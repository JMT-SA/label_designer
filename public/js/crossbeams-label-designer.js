/* eslint-disable no-return-assign */
const UndoEngine = (function UndoEngine() {
  const returnObject = {};

  const undoStack = [];
  let undoIndex = -1;
  let undoButton;
  let redoButton;

  returnObject.canUndo = function canUndo() {
    return (undoStack.length > 0) && (undoIndex >= 0);
  };

  returnObject.canRedo = function canRedo() {
    return undoIndex < undoStack.length - 1;
  };

  // Add a command to the undo list and discard redos
  // beyond the current position if we've performed any.
  returnObject.addCommand = function addCommand(cmd) {
    undoIndex += 1;
    undoStack.splice(undoIndex);
    undoStack.push(cmd);
    undoButton.disabled = false;
  };

  returnObject.undo = function undo() {
    if (!returnObject.canUndo()) {
      throw new Error('ERROR: Cannot call undo at this time.');
    }
    const cmd = undoStack[undoIndex];
    cmd.executeUndo();
    undoIndex -= 1;
    if (redoButton) {
      redoButton.disabled = false;
    }
    if (undoButton && !returnObject.canUndo()) {
      undoButton.disabled = true;
    }
  };

  returnObject.redo = function redo() {
    if (!returnObject.canRedo()) {
      throw new Error('ERROR: Cannot call redo at this time.');
    }
    const cmd = undoStack[undoIndex + 1];
    cmd.executeRedo();
    undoIndex += 1;
    if (undoButton) {
      undoButton.disabled = false;
    }
    if (redoButton && !returnObject.canRedo()) {
      redoButton.disabled = true;
    }
  };

  returnObject.replaceId = function replaceId(prevId, newId) {
    undoStack.forEach((item) => {
      if (item.shapeId && item.shapeId === prevId) {
        item.shapeId = newId;
      }
      if (item.shapeIds && item.shapeIds.includes(prevId)) {
        item.shapeIds[item.shapeIds.indexOf(prevId)] = newId;
      }
    });
  };

  returnObject.setUndoButton = function setUndoButton(btn) {
    undoButton = btn;
    undoButton.disabled = true;
  };

  returnObject.setRedoButton = function setRedoButton(btn) {
    redoButton = btn;
    redoButton.disabled = true;
  };

  // FOR DEBUGGING: Return the undo stack.
  returnObject.debugUndoStack = function debugUndo() {
    return undoStack;
  };

  return returnObject;
}());

const LabelDesigner = (function LabelDesigner() { // eslint-disable-line max-classes-per-file
  const ldState = { changesMade: false };
  const debugSpace = document.getElementById('debugSpace');
  const menuNode = document.getElementById('varMenu');

  /**
   * getClosestInt.
   *
   * Match an integer to its closest equal in an array.
   *
   * @param {array} arr - an array of integers.
   * @param {number} int - an integer to be checked.
   * @returns {number} the closest value from the array.
   */
  const getClosestInt = (arr, int) => {
    let lo;
    let hi;
    if (arr.indexOf(int) !== -1) {
      return int;
    }
    arr.forEach((elem) => {
      if (elem <= int && (lo === undefined || lo < elem)) lo = elem;
      if (elem >= int && (hi === undefined || hi > elem)) hi = elem;
    });
    if (lo === hi) return lo;
    if (lo === undefined) return hi;
    if (hi === undefined) return lo;
    if (int - lo > hi - int) return hi;
    return lo;
  };

  /**
   * adjustWidth.
   *
   * On resize of a shape, ensure the shape does not end up too small to work with.
   *
   * @param {shape} elem - a shape to be resized.
   * @param {number} width - the amount (+/-) to increase or decrease the width.
   * @returns {void}
   */
  const adjustWidth = (elem, width) => {
    let points;

    if (elem.name() === 'line') {
      points = elem.points();
      if (points[0] !== points[2]) {
        points[2] += width;
        if (Math.abs(points[2] - points[0]) < ldState.MIN_DIMENSION) {
          if (points[2] > points[0]) {
            points[2] = points[0] + ldState.MIN_DIMENSION;
          } else {
            points[0] = points[2] + ldState.MIN_DIMENSION;
          }
        }
        elem.points(points);
      }
    } else if (elem.name() === 'variableBox') {
      if (elem.attrs.rotation === 90 || elem.attrs.rotation === 270) {
        elem.height(elem.height() + width);
        if (elem.height() < ldState.MIN_DIMENSION) {
          elem.height(ldState.MIN_DIMENSION);
        }
        elem.getChildren().forEach(node => node.height(elem.height()));
      } else {
        elem.width(elem.width() + width);
        if (elem.width() < ldState.MIN_DIMENSION) {
          elem.width(ldState.MIN_DIMENSION);
        }
        elem.getChildren().forEach(node => node.width(elem.width()));
      }
      ldState.tr.forceUpdate();
    } else if (elem.attrs.rotation === 90 || elem.attrs.rotation === 270) {
      elem.height(elem.height() + width);
      if (elem.height() < ldState.MIN_DIMENSION) {
        elem.height(ldState.MIN_DIMENSION);
      }
    } else {
      elem.width(elem.width() + width);
      if (elem.width() < ldState.MIN_DIMENSION) {
        elem.width(ldState.MIN_DIMENSION);
      }
    }
    ldState.changesMade = true;
  };

  /**
   * adjustHeight.
   *
   * On resize of a shape, ensure the shape does not end up too small to work with.
   *
   * @param {shape} elem - a shape to be resized.
   * @param {number} height - the amount (+/-) to increase or decrease the height.
   * @returns {void}
   */
  const adjustHeight = (elem, height) => {
    let points;
    if (elem.name() === 'line') {
      points = elem.points();
      if (points[1] !== points[3]) {
        points[3] += height;
        if (Math.abs(points[3] - points[1]) < ldState.MIN_DIMENSION) {
          if (points[3] > points[1]) {
            points[3] = points[1] + ldState.MIN_DIMENSION;
          } else {
            points[1] = points[3] + ldState.MIN_DIMENSION;
          }
        }
        elem.points(points);
      }
    } else if (elem.name() === 'variableBox') {
      if (elem.attrs.rotation === 90 || elem.attrs.rotation === 270) {
        elem.width(elem.width() + height);
        if (elem.width() < ldState.MIN_DIMENSION) {
          elem.width(ldState.MIN_DIMENSION);
        }
        elem.getChildren().forEach(node => node.width(elem.width()));
      } else {
        elem.height(elem.height() + height);
        if (elem.height() < ldState.MIN_DIMENSION) {
          elem.height(ldState.MIN_DIMENSION);
        }
        elem.getChildren().forEach(node => node.height(elem.height()));
      }
      ldState.tr.forceUpdate();
    } else if (elem.attrs.rotation === 90 || elem.attrs.rotation === 270) {
      elem.width(elem.width() + height);
      if (elem.width() < ldState.MIN_DIMENSION) {
        elem.width(ldState.MIN_DIMENSION);
      }
    } else {
      elem.height(elem.height() + height);
      if (elem.height() < ldState.MIN_DIMENSION) {
        elem.height(ldState.MIN_DIMENSION);
      }
    }
    ldState.changesMade = true;
  };

  const validFontSize = size => getClosestInt(ldState.fontSizesPx, Number(size));

  const getShapeById = shapeId => ldState.stage.findOne(node => node._id === shapeId); // eslint-disable-line no-underscore-dangle

  const getTextPartById = (shapeId) => {
    const node = getShapeById(shapeId);
    if (!node) { return null; }

    if (node.hasChildren()) {
      return node.getChildren(item => item.getClassName() === 'Text')[0];
    }

    return node;
  };

  /**
   * LdShape.
   *
   * Base for all other shape classes.
   */
  class LdShape {
    /**
     * constructor.
     *
     * @param {number} x - starting point x.
     * @param {number} y - starting point y.
     * @param {number} width - width of the bounding area.
     * @param {number} height - height of the bounding area.
     */
    constructor(x, y, width, height) {
      this.x = x;
      this.y = y;
      this.width = width;
      this.height = height;
    }
  }

  class LdImage extends LdShape {
    generate(opts = {}) {
      // Do not add an image if the input is corrupt...
      if (!opts.imageSource) {
        return null;
      }
      let startX;
      let startY;
      let startW;
      let startH;

      let width = 0;
      let height = 0;
      let loaded = false;
      const img = new Image();
      img.src = opts.imageSource;
      img.onload = () => { ldState.layer.draw(); }; // Ensure image is drawn once it has been loaded.

      this.shape = new Konva.Image({
        name: 'image',
        x: this.x,
        y: this.y,
        image: img,
        draggable: true,
        imageSource: opts.imageSource,
      });

      this.shape.on('transform', () => {
        this.shape.setAttrs({
          width: this.shape.width() * this.shape.scaleX(),
          height: this.shape.height() * this.shape.scaleY(),
          scaleX: 1,
          scaleY: 1,
        });
        ldState.changesMade = true;
      });

      this.shape.on('transformstart', () => {
        startX = this.shape.x();
        startY = this.shape.y();
        startW = this.shape.width();
        startH = this.shape.height();
      });
      this.shape.on('transformend', () => {
        if (ldState.selectedMultiple.length > 0) {
          return;
        }

        const change = {
          x: Math.round(this.shape.x()) - Math.round(startX),
          y: Math.round(this.shape.y()) - Math.round(startY),
          width: Math.round(this.shape.width() - startW),
          height: Math.round(this.shape.height() - startH),
        };

        UndoEngine.addCommand({
          shapeId: this.shape._id, // eslint-disable-line no-underscore-dangle
          action: 'resize',
          current: change,
          previous: {
            x: change.x * -1,
            y: change.y * -1,
            width: change.width * -1,
            height: change.height * -1,
          },
          executeUndo() {
            const item = getShapeById(this.shapeId);

            if (this.previous.x !== 0 || this.previous.y !== 0) {
              item.move({ x: this.previous.x, y: this.previous.y });
            }
            if (this.previous.width !== 0) {
              adjustWidth(item, this.previous.width);
            }
            if (this.previous.height !== 0) {
              adjustHeight(item, this.previous.height);
            }
            ldState.stage.draw();
            console.log('UNDO', this.shapeId, this.previous);
          },
          executeRedo() {
            const item = getShapeById(this.shapeId);

            if (this.current.x !== 0 || this.current.y !== 0) {
              item.move({ x: this.current.x, y: this.current.y });
            }
            if (this.current.width !== 0) {
              adjustWidth(item, this.current.width);
            }
            if (this.current.height !== 0) {
              adjustHeight(item, this.current.height);
            }
            ldState.stage.draw();
            console.log('REDO', this.shapeId, this.current);
          },
        });
      });

      loaded = true;
      if (this.width) {
        this.shape.width(this.width);
      } else {
        width = this.shape.image().width;
        // Provide non-zero dimension if image is not fully loaded yet,
        if (width === 0) {
          loaded = false;
          width = 30;
        }
        this.shape.width(width);
      }
      if (this.height) {
        this.shape.height(this.height);
      } else {
        height = this.shape.image().height;
        // Provide non-zero dimension if image is not fully loaded yet,
        if (height === 0) {
          loaded = false;
          height = 30;
        }
        this.shape.height(height);
      }

      // The image might not have finished loading soon enough to have dimensions,
      // so check in a timeout and adjust the width and height accordingly.
      if (!loaded) {
        const aShape = this.shape;
        setTimeout(function checkImgLoad() {
          width = aShape.image().width;
          height = aShape.image().height;
          if (width === 0 || height === 0) {
            setTimeout(checkImgLoad, 250);
          } else {
            aShape.height(height);
            aShape.width(width);
            aShape.draw();
          }
        }, 250);
      }
      return this.shape;
    }
  }

  class LdRect extends LdShape {
    generate(opts = {}) {
      let startX;
      let startY;
      let startW;
      let startH;

      this.shape = new Konva.Rect({
        name: 'rect',
        x: this.x,
        y: this.y,
        width: this.width,
        height: this.height,
        stroke: 'black',
        strokeWidth: opts.strokeWidth || 2,
        strokeScaleEnabled: false,
        draggable: true,
      });

      this.shape.on('transform', () => {
        this.shape.setAttrs({
          width: this.shape.width() * this.shape.scaleX(),
          height: this.shape.height() * this.shape.scaleY(),
          scaleX: 1,
          scaleY: 1,
        });
        ldState.changesMade = true;
      });

      this.shape.on('transformstart', () => {
        startX = this.shape.x();
        startY = this.shape.y();
        startW = this.shape.width();
        startH = this.shape.height();
      });
      this.shape.on('transformend', () => {
        if (ldState.selectedMultiple.length > 0) {
          return;
        }
        // x & y could move when resized...
        const change = {
          x: Math.round(this.shape.x()) - Math.round(startX),
          y: Math.round(this.shape.y()) - Math.round(startY),
          width: Math.round(this.shape.width() - startW),
          height: Math.round(this.shape.height() - startH),
        };
        console.log('after', change);

        UndoEngine.addCommand({
          shapeId: this.shape._id, // eslint-disable-line no-underscore-dangle
          action: 'resize',
          current: change,
          previous: {
            x: change.x * -1,
            y: change.y * -1,
            width: change.width * -1,
            height: change.height * -1,
          },
          executeUndo() {
            const item = getShapeById(this.shapeId);

            if (this.previous.x !== 0 || this.previous.y !== 0) {
              item.move({ x: this.previous.x, y: this.previous.y });
            }
            if (this.previous.width !== 0) {
              adjustWidth(item, this.previous.width);
            }
            if (this.previous.height !== 0) {
              adjustHeight(item, this.previous.height);
            }
            ldState.stage.draw();
            console.log('UNDO', this.shapeId, this.previous);
          },
          executeRedo() {
            const item = getShapeById(this.shapeId);

            if (this.current.x !== 0 || this.current.y !== 0) {
              item.move({ x: this.current.x, y: this.current.y });
            }
            if (this.current.width !== 0) {
              adjustWidth(item, this.current.width);
            }
            if (this.current.height !== 0) {
              adjustHeight(item, this.current.height);
            }
            ldState.stage.draw();
            console.log('REDO', this.shapeId, this.current);
          },
        });
      });
      return this.shape;
    }
  }

  class LdLine extends LdShape {
    constructor(x, y, width, height, endX, endY) {
      super(x, y, width, height);
      this.endX = endX;
      this.endY = endY;
    }

    generate(opts = {}) {
      let startPoints;

      this.shape = new Konva.Line({
        name: 'line',
        points: [this.x, this.y, this.endX, this.endY],
        stroke: 'black',
        strokeWidth: opts.strokeWidth || 2,
        strokeScaleEnabled: false,
        draggable: true,
        hitStrokeWidth: 10,
      });

      this.shape.on('dragend', () => {
        const points = this.shape.points();
        const newX = this.shape.x();
        const newY = this.shape.y();
        this.shape.points([points[0] + newX, points[1] + newY, points[2] + newX, points[3] + newY]);
        this.shape.x(0);
        this.shape.y(0);
        ldState.changesMade = true;
      });

      this.shape.on('transform', () => {
        const points = this.shape.points();
        const x = this.shape.x();
        const y = this.shape.y();
        // console.log('x,y', x, y);

        this.shape.setAttrs({
          points: [
            x + (points[0] * this.shape.scaleX()),
            y + (points[1] * this.shape.scaleY()),
            x + (points[2] * this.shape.scaleX()),
            y + (points[3] * this.shape.scaleY()),
          ],
          scaleX: 1,
          scaleY: 1,
          x: 0,
          y: 0,
        });
        ldState.changesMade = true;
      });

      this.shape.on('transformstart', () => {
        startPoints = this.shape.points().slice();
      });
      this.shape.on('transformend', () => {
        if (ldState.selectedMultiple.length > 0) {
          return;
        }
        const newPoints = this.shape.points().slice();
        console.log('ppts', startPoints, newPoints);
        const change = {
          x: Math.round(newPoints[0] - startPoints[0]),
          y: Math.round(newPoints[1] - startPoints[1]),
          x2: Math.round(newPoints[2] - startPoints[2]),
          y2: Math.round(newPoints[3] - startPoints[3]),
        };
        console.log('after', change);

        UndoEngine.addCommand({
          shapeId: this.shape._id, // eslint-disable-line no-underscore-dangle
          action: 'resize',
          current: change,
          previous: {
            x: change.x * -1,
            y: change.y * -1,
            x2: change.x2 * -1,
            y2: change.y2 * -1,
          },
          executeUndo() {
            const item = getShapeById(this.shapeId);
            const currPoints = item.points();
            item.points([currPoints[0] + this.previous.x,
              currPoints[1] + this.previous.y,
              currPoints[2] + this.previous.x2,
              currPoints[3] + this.previous.y2]);
            console.log('undo line', item.points());
            ldState.stage.draw();
            console.log('UNDO', this.shapeId, this.previous);
          },
          executeRedo() {
            const item = getShapeById(this.shapeId);
            const currPoints = item.points();
            item.points([currPoints[0] + this.current.x,
              currPoints[1] + this.current.y,
              currPoints[2] + this.current.x2,
              currPoints[3] + this.current.y2]);
            ldState.stage.draw();
            console.log('REDO', this.shapeId, this.current);
          },
        });
      });

      return this.shape;
    }
  }

  // VariableBox
  class LdVariable extends LdShape {
    generate(opts = {}) {
      let rotation = opts.rotation || 0;
      if (rotation === 360) {
        rotation = 0;
      }
      const optAttrs = opts.varAttrs || {};
      const varAttrs = {
        whiteOnBlack: optAttrs.whiteOnBlack || false,
        barcode: optAttrs.barcode || false,
        barcodeText: optAttrs.barcodeText || false,
        barcodeTop: optAttrs.barcodeTop || 'true',
        barcodeWidthFactor: optAttrs.barcodeWidthFactor || 1.5,
        barcodeSymbology: optAttrs.barcodeSymbology || 'CODE_128',
        staticValue: optAttrs.staticValue || null,
      };

      let txtFill = 'black';
      let rectFill = '#188FA7';
      if (varAttrs.whiteOnBlack) {
        txtFill = '#CA48BC';
        rectFill = '#CA48BC';
      }
      if (varAttrs.barcode) {
        txtFill = '#9E3B00';
        rectFill = '#9E3B00';
      }

      let vn;
      if (opts.varNum) {
        vn = opts.varNum;
        ldState.varNum = Math.max(ldState.varNum, vn);
      } else {
        ldState.varNum += 1;
        vn = ldState.varNum;
      }

      this.shape = new Konva.Group({
        x: this.x,
        y: this.y,
        width: this.width,
        height: this.height,
        offset: 0,
        draggable: true,
        varNum: vn,
        varType: opts.varType || 'unset',
        varAttrs,
        rotation,
      });

      const txtPart = new Konva.Text({
        name: 'text',
        x: 0,
        y: 0,
        width: this.width,
        height: this.height,
        fontSize: validFontSize(opts.fontSize || 22),
        fontFamily: opts.fontFamily || 'Arial',
        text: opts.text || 'Unset Variable',
        fill: txtFill,
        fontStyle: opts.fontStyle || 'normal',
        textDecoration: opts.textDecoration || '',
        align: opts.align || 'left',
      });
      const rectPart = new Konva.Rect({
        name: 'rect',
        x: 0,
        y: 0,
        width: this.width,
        height: this.height,
        stroke: opts.stroke || rectFill,
        strokeWidth: 2,
        strokeScaleEnabled: false,
      });

      // Ensure the text in the variable does not stretch with transforming:
      this.shape.on('transformend', () => {
        const txtElem = this.shape.getChildren(node => node.getClassName() === 'Text')[0];
        const rectElem = this.shape.getChildren(node => node.getClassName() === 'Rect')[0];

        txtElem.setAttrs({
          width: this.shape.width() * this.shape.scaleX(),
          height: this.shape.height() * this.shape.scaleY(),
          scaleX: 1,
          scaleY: 1,
        });

        rectElem.setAttrs({
          width: this.shape.width() * this.shape.scaleX(),
          height: this.shape.height() * this.shape.scaleY(),
          scaleX: 1,
          scaleY: 1,
        });

        this.shape.setAttrs({
          width: Math.max(this.shape.width() * this.shape.scaleX(), ldState.MIN_DIMENSION),
          height: Math.max(this.shape.height() * this.shape.scaleY(), ldState.MIN_DIMENSION),
          scaleX: 1,
          scaleY: 1,
        });

        ldState.layerVar.draw();
        ldState.tr.forceUpdate();
        ldState.changesMade = true;
      });

      // On double-click of a variable, focus on the text editor
      this.shape.on('dblclick', () => {
        ldState.textButtons.text.focus();
        ldState.selectedShape = this.shape;
      });

      this.shape.add(rectPart);
      this.shape.add(txtPart);
      this.shape.addName('variableBox');
      return this.shape;
    }
  }

  class LdText extends LdShape {
    generate(opts = {}) {
      let startX;
      let startY;
      let startW;
      let startH;

      this.shape = new Konva.Text({
        name: 'textBox',
        x: this.x,
        y: this.y,
        width: this.width,
        height: this.height,
        fontSize: validFontSize(opts.fontSize || 22),
        fontFamily: opts.fontFamily || 'Arial',
        text: opts.text || 'Text',
        fill: 'black',
        draggable: true,
        fontStyle: opts.fontStyle || 'normal',
        textDecoration: opts.textDecoration || '',
        align: opts.align || 'left',
        rotation: opts.rotation || 0,
      });

      this.shape.on('dblclick', () => {
        ldState.textButtons.text.focus();
        ldState.selectedShape = this.shape;
      });

      this.shape.on('transform', () => {
        this.shape.setAttrs({
          width: this.shape.width() * this.shape.scaleX(),
          height: this.shape.height() * this.shape.scaleY(),
          scaleX: 1,
          scaleY: 1,
        });
        ldState.changesMade = true;
      });

      this.shape.on('transformstart', () => {
        startX = this.shape.x();
        startY = this.shape.y();
        startW = this.shape.width();
        startH = this.shape.height();
      });
      this.shape.on('transformend', () => {
        if (ldState.selectedMultiple.length > 0) {
          return;
        }
        const change = {
          x: Math.round(this.shape.x()) - Math.round(startX),
          y: Math.round(this.shape.y()) - Math.round(startY),
          width: Math.round(this.shape.width() - startW),
          height: Math.round(this.shape.height() - startH),
        };

        UndoEngine.addCommand({
          shapeId: this.shape._id, // eslint-disable-line no-underscore-dangle
          action: 'resize',
          current: change,
          previous: {
            x: change.x * -1,
            y: change.y * -1,
            width: change.width * -1,
            height: change.height * -1,
          },
          executeUndo() {
            const item = getShapeById(this.shapeId);

            if (this.previous.x !== 0 || this.previous.y !== 0) {
              item.move({ x: this.previous.x, y: this.previous.y });
            }
            if (this.previous.width !== 0) {
              adjustWidth(item, this.previous.width);
            }
            if (this.previous.height !== 0) {
              adjustHeight(item, this.previous.height);
            }
            ldState.stage.draw();
            console.log('UNDO', this.shapeId, this.previous);
          },
          executeRedo() {
            const item = getShapeById(this.shapeId);

            if (this.current.x !== 0 || this.current.y !== 0) {
              item.move({ x: this.current.x, y: this.current.y });
            }
            if (this.current.width !== 0) {
              adjustWidth(item, this.current.width);
            }
            if (this.current.height !== 0) {
              adjustHeight(item, this.current.height);
            }
            ldState.stage.draw();
            console.log('REDO', this.shapeId, this.current);
          },
        });
      });
      return this.shape;
    }
  }

  class LdEllipse extends LdShape {
    generate(opts = {}) {
      this.shape = new Konva.Ellipse({
        name: 'ellipse',
        x: this.x + (this.width / 2),
        y: this.y + (this.height / 2),
        radiusX: this.width / 2,
        radiusY: this.height / 2,
        stroke: 'black',
        strokeWidth: opts.strokeWidth || 2,
        strokeScaleEnabled: false,
        draggable: true,
      });
      return this.shape;
    }
  }

  /**
   * LdMarshal.
   *
   * Class to control serialising and de-serialising shapes via dump() and load().
   */
  class LdMarshal {
    /**
     * constructor.
     *
     * @param {shape|node} elem - the shape to be dumped, or the node to be loaded as a shape.
     */
    constructor(elem) {
      this.elem = elem;
    }

    /**
     * dump.
     *
     * Dump a shape.
     *
     * @returns {object} a representation of the shape.
     */
    dump() {
      let node;
      let txtObj;

      node = {
        name: this.elem.name(),
        x: this.elem.x(),
        y: this.elem.y(),
        width: this.elem.width(),
        height: this.elem.height(),
      };

      if (this.elem.name() === 'image') {
        node.imageSource = this.elem.getAttr('imageSource');
        node.width = this.elem.getAttr('width') * this.elem.getAttr('scaleX') || 1;
        node.height = this.elem.getAttr('height') * this.elem.getAttr('scaleY') || 1;
      }

      if (this.elem.name() === 'line') {
        node.x = this.elem.points()[0];
        node.y = this.elem.points()[1];
        node.endX = this.elem.points()[2];
        node.endY = this.elem.points()[3];
      }

      if (this.elem.name() === 'ellipse') {
        node.x = this.elem.x() - this.elem.radiusX();
        node.y = this.elem.y() - this.elem.radiusY();
        node.width = this.elem.radiusX() * 2;
        node.height = this.elem.radiusY() * 2;
      }

      if (['line', 'rect', 'ellipse'].includes(this.elem.name())) {
        node.strokeWidth = this.elem.getAttr('strokeWidth');
      }

      if (this.elem.name() === 'textBox') {
        node.fontSize = this.elem.fontSize();
        node.fontFamily = this.elem.fontFamily();
        node.fontStyle = this.elem.fontStyle();
        node.textDecoration = this.elem.textDecoration();
        node.text = this.elem.text();
        node.align = this.elem.align();
        node.rotation = this.elem.rotation();
      }

      if (this.elem.name() === 'variableBox') {
        node = {
          x: this.elem.x(),
          y: this.elem.y(),
          name: this.elem.name(),
          width: this.elem.width(),
          height: this.elem.height(),
          rotation: this.elem.rotation(),
        };

        node.variableNumber = `F${this.elem.getAttr('varNum')}`;
        node.varType = this.elem.getAttr('varType');
        node.varAttrs = this.elem.getAttr('varAttrs');
        // var name, barcode attrs, white etc

        txtObj = this.elem.getChildren(item => item.getClassName() === 'Text')[0];
        node.fontSize = txtObj.fontSize();
        node.fontFamily = txtObj.fontFamily();
        node.fontStyle = txtObj.fontStyle();
        node.textDecoration = txtObj.textDecoration();
        node.text = txtObj.text();
        node.align = txtObj.align();
      }

      return node;
    }

    /**
     * load.
     *
     * Load a shape.
     *
     * @param {?number} offset - number of pixels to offset the top left x,y points. Use non-zero for paste so that a shape is offset from its origin.
     * @returns {shape} the generated shape.
     */
    load(offset = 0) {
      let shape;
      let item;

      if (this.elem.name === 'image') {
        shape = new LdImage(this.elem.x + offset, this.elem.y + offset, this.elem.width, this.elem.height);
        item = shape.generate(this.elem);
        if (item !== null) {
          ldState.layer.add(item);
        }
      }
      if (this.elem.name === 'rect') {
        shape = new LdRect(this.elem.x + offset, this.elem.y + offset, this.elem.width, this.elem.height);
        item = shape.generate(this.elem);
        ldState.layer.add(item);
      }
      if (this.elem.name === 'ellipse') {
        shape = new LdEllipse(this.elem.x + offset, this.elem.y + offset, this.elem.width, this.elem.height); // check this seems to increase scale...
        item = shape.generate(this.elem);
        ldState.layer.add(item);
      }
      if (this.elem.name === 'line') {
        // console.log(this.elem);
        shape = new LdLine(this.elem.x + offset, this.elem.y + offset,
          this.elem.width, this.elem.height,
          this.elem.endX + offset, this.elem.endY + offset);
        item = shape.generate(this.elem);
        ldState.layer.add(item);
      }
      if (this.elem.name === 'textBox') {
        shape = new LdText(this.elem.x + offset, this.elem.y + offset, this.elem.width, this.elem.height);
        item = shape.generate(this.elem);
        ldState.layer.add(item);
      }
      if (this.elem.name === 'variableBox') {
        shape = new LdVariable(this.elem.x + offset, this.elem.y + offset, this.elem.width, this.elem.height);
        item = shape.generate(this.elem);
        ldState.layerVar.add(item);
        if (offset !== 0) {
          ldState.layerVar.draw();
        }
      } else if (offset !== 0) {
        ldState.layer.draw();
      }

      return item;
    }
  }
  // --- END OF SHAPES

  // Return the selected text object or the text object within the selected group.
  /**
   * resolveTextObject.
   *
   * @param {shape} item - a text or variable shape.
   * @returns {shape} the text object or the variable's text part.
   */
  const resolveTextObject = (item) => {
    const txtObj = item || ldState.selectedShape;
    if (txtObj.hasChildren()) {
      const tmp = txtObj.getChildren(node => node.getClassName() === 'Text')[0];
      return tmp;
    }
    return txtObj;
  };

  const LINE_TYPES = {
    line: true,
    rect: true,
    ellipse: true,
  };

  /**
   * lineTypeSelected.
   *
   * Is the selected shape one that has a `stroke` attribute?
   *
   * @returns {boolean} true if the shape is a line, rect or ellipse, else false.
   */
  const lineTypeSelected = () => {
    if (LINE_TYPES[ldState.selectedShape.name()]) return true;

    return false;
  };

  const TEXT_TYPES = {
    textBox: true,
    variableBox: true,
  };

  const textTypeSelected = () => {
    // console.log('type', ldState.selectedShape.name(), TEXT_TYPES[ldState.selectedShape.name()]);
    if (TEXT_TYPES[ldState.selectedShape.name()]) return true;

    return false;
  };

  const setLineButtons = (enable) => {
    // console.log('lineW', ldState.lineWidth);
    if (enable) {
      ldState.lineWidth.disabled = false;
      ldState.lineWidthImg.disabled = false;
      ldState.lineWidth.value = ldState.selectedShape.strokeWidth();
    } else {
      ldState.lineWidth.disabled = true;
      ldState.lineWidthImg.disabled = true;
      ldState.lineWidth.value = 2;
    }
  };

  const applyTextState = () => {
    if (ldState.selectedShape && (ldState.selectedShape.name() === 'variableBox' || ldState.selectedShape.name() === 'textBox')) {
      const txtObj = resolveTextObject();
      ldState.textButtons.bold.dataset.selected = txtObj.fontStyle().split(' ').includes('bold');
      ldState.textButtons.italic.dataset.selected = txtObj.fontStyle().split(' ').includes('italic');
      ldState.textButtons.underline.dataset.selected = txtObj.textDecoration() === 'underline';
      ldState.textButtons.lJust.dataset.selected = txtObj.align() === 'left';
      ldState.textButtons.cJust.dataset.selected = txtObj.align() === 'center';
      ldState.textButtons.rJust.dataset.selected = txtObj.align() === 'right';
      ldState.textButtons.text.value = txtObj.text();
      ldState.textButtons.fontSize.value = txtObj.fontSize();
      ldState.textButtons.fontFamily.value = txtObj.fontFamily();
    } else if (ldState.selectedMultiple.length === 0) {
      document.querySelectorAll('[data-text="button"]').forEach(elem => elem.dataset.selected = false);
      document.querySelector('[data-alignment="left"]').dataset.selected = true;
      ldState.textButtons.fontSize.value = 22;
      ldState.textButtons.fontFamily.value = 'Arial';
      ldState.textButtons.text.value = '';
    }
  };

  const applyTextStyle = (enable, style, shape) => {
    const txtObj = resolveTextObject(shape);
    if (style === 'underline') {
      txtObj.textDecoration(enable ? 'underline' : '');
    } else {
      const sty = txtObj.fontStyle();
      let ar = sty.split(' ');
      if (sty === 'normal') {
        ar = [];
      }
      ar = ar.filter(item => item !== style);
      if (enable) {
        ar.push(style);
      }
      if (ar.length === 0) {
        ar = ['normal'];
      }
      txtObj.fontStyle(ar.join(' '));
    }
    ldState.changesMade = true;
  };

  const applyTextAlignment = (align, item) => {
    const txtObj = resolveTextObject(item);
    txtObj.align(align);
  };

  const updateDisplay = (coords) => {
    const text = coords.map(item => (item < 0 ? 0 : item)).join(', ');
    document.querySelector('span.currentCoords').textContent = `(${text})`;
  };
  const getTopMarker = () => document.querySelector('.top-marker');
  const getLeftMarker = () => document.querySelector('.left-marker');
  const updateTopMarker = (coords) => {
    getTopMarker().setAttribute('style', `padding-left:${coords[0]}px;`);
  };
  const updateLeftMarker = (coords) => {
    getLeftMarker().setAttribute('style', `padding-top:${coords[1]}px;`);
  };

  const setAllowedFontOptions = (variable) => {
    Array.from(ldState.textButtons.fontFamily.children).forEach((option) => { option.disabled = false; });
    if (variable) {
      Array.from(ldState.textButtons.fontFamily.children).forEach((option) => {
        if (option.value === 'Lato Light') {
          option.disabled = true;
        }
      });
    }
  };

  const setTextButtons = (enable) => {
    applyTextState();
    if (enable) {
      document.querySelectorAll('[data-text="button"]').forEach(elem => elem.disabled = false);
      document.querySelectorAll('[data-text="select"]').forEach(elem => elem.disabled = false);
      document.querySelector('#textinput').disabled = false;
      setAllowedFontOptions(ldState.selectedShape.name() === 'variableBox');
    } else {
      document.querySelectorAll('[data-text="button"]').forEach(elem => elem.disabled = true);
      document.querySelectorAll('[data-text="select"]').forEach(elem => elem.disabled = true);
      document.querySelector('#textinput').disabled = true;
    }
  };

  const setSelectedButtons = (enable, textType) => {
    if (enable) {
      document.querySelector('[data-action="remove"]').disabled = false;
      if (textType) {
        document.querySelector('[data-action="rotate"]').disabled = false;
      } else {
        document.querySelector('[data-action="rotate"]').disabled = true;
      }
    } else {
      document.querySelector('[data-action="remove"]').disabled = true;
      document.querySelector('[data-action="rotate"]').disabled = true;
    }
  };

  const setAlignButtons = (enable) => {
    document.querySelectorAll('[data-action="align"]').forEach(elem => elem.disabled = !enable);
  };

  const setCopyButtons = (enable) => {
    document.querySelector('[data-action="copy"]').disabled = !enable;
  };

  const setButtonsForMultiple = () => {
    let list;

    setCopyButtons(true);

    // --- Stroke - for shapes
    list = ldState.selectedMultiple.map((item) => {
      if (['rect', 'line', 'ellipse'].includes(item.name())) {
        return item.strokeWidth();
      }
      return 99;
    });

    if (list[0] !== 99 && list.every(attr => attr === list[0])) {
      ldState.lineWidth.disabled = false;
      ldState.lineWidthImg.disabled = false;
      ldState.lineWidth.value = list[0];
    }

    // --- Text attrs
    list = ldState.selectedMultiple.map((item) => {
      if (['rect', 'line', 'ellipse', 'image'].includes(item.name())) {
        return '';
      }
      if (item.name() === 'variableBox') {
        return 'var';
      }
      return 'txt';
    });

    if (list[0] !== '' && list.every(attr => ['txt', 'var'].includes(attr))) {
      document.querySelectorAll('[data-text="button"]').forEach(elem => elem.disabled = false);
      document.querySelectorAll('[data-text="select"]').forEach(elem => elem.disabled = false);
      document.querySelector('#textinput').disabled = true;
      Array.from(ldState.textButtons.fontFamily.children).forEach((option) => { option.disabled = false; });
      if (list.some(attr => attr === 'var')) {
        Array.from(ldState.textButtons.fontFamily.children).forEach((option) => {
          if (option.value === 'Lato Light') {
            option.disabled = true;
          }
        });
      }
    } else {
      document.querySelectorAll('[data-text="button"]').forEach(elem => elem.disabled = true);
      document.querySelectorAll('[data-text="select"]').forEach(elem => elem.disabled = true);
      document.querySelector('#textinput').disabled = true;
    }
  };

  const registerMoveUndo = (selectedShapes, move) => {
    const affectedShapes = selectedShapes.map(item => item._id); // eslint-disable-line no-underscore-dangle
    const prevState = { x: move.x === 0 ? 0 : move.x * -1, y: move.y === 0 ? 0 : move.y * -1 };

    UndoEngine.addCommand({
      shapeIds: affectedShapes,
      action: 'move',
      current: move,
      previous: prevState,
      executeUndo() {
        let item;
        let points;
        this.shapeIds.forEach((id) => {
          item = getShapeById(id);
          if (item.name() === 'line') {
            points = item.points();
            item.points([points[0] + this.previous.x, points[1] + this.previous.y, points[2] + this.previous.x, points[3] + this.previous.y]);
          } else {
            item.move(this.previous);
          }
        });
        ldState.stage.draw();
        console.log('UNDO', this.shapeIds, this.action, this.previous);
      },
      executeRedo() {
        let item;
        let points;
        this.shapeIds.forEach((id) => {
          item = getShapeById(id);
          if (item.name() === 'line') {
            points = item.points();
            item.points([points[0] + this.current.x, points[1] + this.current.y, points[2] + this.current.x, points[3] + this.current.y]);
          } else {
            item.move(this.current);
          }
        });
        ldState.stage.draw();
        console.log('REDO', this.shapeIds, this.action, this.current);
      },
    });
  };

  const setNodeSelectionColours = (change, nodes) => {
    let txtElem;
    let rectElem;
    let txtFill = 'black';
    let rectFill = '#188FA7';

    nodes.forEach((node) => {
      if (change) {
        if (node.name() === 'textBox') {
          node.fill('orange');
        } else if (node.name() === 'variableBox') {
          txtElem = node.getChildren(item => item.getClassName() === 'Text')[0];
          rectElem = node.getChildren(item => item.getClassName() === 'Rect')[0];
          txtElem.fill('orange');
          rectElem.stroke('orange');
        } else {
          node.stroke('orange'); // image...?
        }
      } else {
        if (node.name() === 'textBox') {
          node.fill('black');
        } else if (node.name() === 'variableBox') {
          txtElem = node.getChildren(item => item.getClassName() === 'Text')[0];
          rectElem = node.getChildren(item => item.getClassName() === 'Rect')[0];
          txtFill = 'black';
          rectFill = '#188FA7';
          if (node.attrs.varAttrs.whiteOnBlack) {
            txtFill = '#CA48BC';
            rectFill = '#CA48BC';
          }
          if (node.attrs.varAttrs.barcode) {
            txtFill = '#9E3B00';
            rectFill = '#9E3B00';
          }
          txtElem.fill(txtFill);
          rectElem.stroke(rectFill);
        } else {
          node.stroke('black'); // image...?
        }
      }
    });
  };

  const init = (labelConfig) => {
    UndoEngine.setUndoButton(document.querySelector('[data-action="undo"]'));
    UndoEngine.setRedoButton(document.querySelector('[data-action="redo"]'));

    ldState.MIN_DIMENSION = 20;
    ldState.selectedShape = undefined;
    ldState.selectedMultiple = [];
    ldState.currentMode = 'select';
    ldState.currentDrawType = undefined;
    ldState.varNum = 0;
    ldState.clipboard = { shapes: [] };
    ldState.copyOffset = 5;
    ldState.dragStartX = 0;
    ldState.dragStartY = 0;
    // ldState.startTransform = undefined;

    ldState.labelConfig = labelConfig;
    ldState.savePath = labelConfig.savePath;

    ldState.lineWidth = document.querySelector('#stroke-width');
    ldState.lineWidthImg = document.querySelector('#stroke-width-img');
    // Show/hide the help button
    if (labelConfig.helpURL && labelConfig.helpURL !== '') {
      document.getElementById('ld_help').href = labelConfig.helpURL;
      document.getElementById('ld_help_wrap').hidden = false;
    }
    document.getElementById('labelName').innerHTML = labelConfig.labelName;

    ldState.lineWidth.addEventListener('change', () => {
      const affectedShapes = [];
      let prevState;

      if (ldState.selectedMultiple.length > 0) {
        ldState.selectedMultiple.forEach((item) => {
          if (!prevState) {
            prevState = item.strokeWidth();
          }
          item.strokeWidth(Number(ldState.lineWidth.value));
          affectedShapes.push(item._id); // eslint-disable-line no-underscore-dangle
        });
      } else {
        prevState = ldState.selectedShape.strokeWidth();
        ldState.selectedShape.strokeWidth(Number(ldState.lineWidth.value));
        affectedShapes.push(ldState.selectedShape._id); // eslint-disable-line no-underscore-dangle
      }
      ldState.stage.draw();
      ldState.changesMade = true;

      UndoEngine.addCommand({
        shapeIds: affectedShapes,
        action: 'strokeWidth',
        current: Number(ldState.lineWidth.value),
        previous: prevState,
        executeUndo() {
          let item;
          this.shapeIds.forEach((id) => {
            item = getShapeById(id);
            item.strokeWidth(this.previous);
          });
          if ((ldState.selectedShape && this.shapeIds.includes(ldState.selectedShape._id)) // eslint-disable-line no-underscore-dangle
            || (ldState.selectedMultiple.length > 0 && ldState.selectedMultiple.some(multi => this.shapeIds.includes(multi._id)))) { // eslint-disable-line no-underscore-dangle
            ldState.lineWidth.value = this.previous;
          }
          ldState.stage.draw();
          console.log('UNDO', this.shapeIds, this.action, this.previous);
        },
        executeRedo() {
          let item;
          this.shapeIds.forEach((id) => {
            item = getShapeById(id);
            item.strokeWidth(this.current);
          });
          if ((ldState.selectedShape && this.shapeIds.includes(ldState.selectedShape._id)) // eslint-disable-line no-underscore-dangle
            || (ldState.selectedMultiple.length > 0 && ldState.selectedMultiple.some(multi => this.shapeIds.includes(multi._id)))) { // eslint-disable-line no-underscore-dangle
            ldState.lineWidth.value = this.current;
          }
          ldState.stage.draw();
          console.log('REDO', this.shapeIds, this.action, this.current);
        },
      });
    });

    ldState.textButtons = {
      bold: document.querySelector('#textBold'),
      underline: document.querySelector('#textUnderline'),
      italic: document.querySelector('#textItalic'),
      lJust: document.querySelector('#textLeftJust'),
      cJust: document.querySelector('#textCentreJust'),
      rJust: document.querySelector('#textRightJust'),
      text: document.querySelector('#textinput'),
      fontSize: document.querySelector('#font-size'),
      fontFamily: document.querySelector('#font-family'),
    };

    // Store all possible font size values so anything out-of-range can be corrected.
    ldState.fontSizesPx = Array.from(ldState.textButtons.fontSize.options).map(x => Number(x.value));

    ldState.outline = new Konva.Rect({
      x: 0,
      y: 0,
      width: 50,
      height: 50,
      dash: [10, 5],
      stroke: '#555555',
      strokeWidth: 1,
    });

    // Initialise image dialog
    ldState.imgUpDialog = new window.A11yDialog(document.getElementById('image-dialog-form'));
    ldState.imgUpDialog.on('hide', () => {
      document.querySelector('#image-dialog-form .notice').setAttribute('style', 'display:none;');
      document.querySelector('form.upload-image').reset();
      document.querySelectorAll('[data-active]').forEach(elem => elem.dataset.active = 'false');
      document.querySelector('[data-action="select"]').dataset.active = 'true';
      document.querySelector('[data-action="select"]').focus();
    });

    // Add image button click
    document.querySelector('#image-dialog-form button.upload').addEventListener('click', () => {
      const files = document.querySelector('#image-dialog-form input[type="file"]').files;
      let marshal;

      if (files.length > 0) {
        const file = files[0];
        if (file) {
          const reader = new FileReader();
          if (ldState.tr.nodes().length > 1) {
            setNodeSelectionColours(false, ldState.tr.nodes());
          }

          reader.addEventListener('load', () => {
            const shape = new LdImage(0, 0);
            const recttmp = shape.generate({ imageSource: reader.result });
            ldState.layer.add(recttmp);
            ldState.tr.nodes([recttmp]);

            marshal = new LdMarshal(recttmp);
            const newNode = marshal.dump();
            UndoEngine.addCommand({
              shapeId: recttmp._id, // eslint-disable-line no-underscore-dangle
              action: 'addImage',
              current: newNode,
              previous: null,
              executeUndo() {
                const item = getShapeById(this.shapeId);
                // remove from selection if the shape we are about to delete is selected.
                if (ldState.tr.nodes().indexOf(item) >= 0) {
                  const hold = ldState.tr.nodes().slice(); // use slice to have new copy of array
                  // remove node from array
                  hold.splice(hold.indexOf(item), 1);
                  ldState.tr.nodes(hold);
                }

                item.destroy();
                ldState.stage.draw();
                console.log('UNDO', this.shapeId, this.action, this.previous);
              },
              executeRedo() {
                marshal = new LdMarshal(newNode);
                const item = marshal.load();
                UndoEngine.replaceId(this.shapeId, item._id); // eslint-disable-line no-underscore-dangle
                ldState.stage.draw();
                console.log('REDO', this.shapeId, this.action, this.current);
              },
            });

            // reset draw mode
            ldState.currentMode = 'select';
            ldState.selectedShape = recttmp;
            // action?
            ldState.stage.fire('ldSelectOne');
            ldState.imgUpDialog.hide();
            ldState.stage.draw();
            ldState.selectedMultiple = [];
            setSelectedButtons(true);
            setLineButtons(false);
            setTextButtons(false);
            document.querySelectorAll('[data-active]').forEach(elem => elem.dataset.active = 'false');
            document.querySelector('[data-action="select"]').dataset.active = 'true';
            ldState.changesMade = true;
          });
          reader.readAsDataURL(file);
        }
      } else {
        document.querySelector('#image-dialog-form .notice').removeAttribute('style');
      }
    });

    // UI elements for defining variables
    ldState.variableUI = {
      varDialog: new window.A11yDialog(document.getElementById('variable-info-dialog-form')),
      varForm: document.querySelector('form.variable-info-form'),
      errBox: document.querySelector('form.variable-info-form .notice'),
      variableSelect: document.querySelector('#vars'),
      whiteOnBlack: document.querySelector('#white_on_black'),
      barcodeOptions: document.querySelector('.barcode-options'),
      compoundVars: document.querySelector('#compound_vars'),
      compoundSel: document.querySelector('#varsCmp'),
      compoundTxt: document.querySelector('#textCmp'),
      compoundRes: document.querySelector('#compound_result'),
      compoundDisp: document.querySelector('#compound_display'),
      staticInput: document.querySelector('#static_barcode'),
      staticInputValue: document.querySelector('#static_barcode_value'),
      barcodeSymbology: document.querySelector('#barcode_symbology'),
      barcodeBoolWrapper: document.querySelector('#barcode_bool_wrapper'),
      barcodeBool: document.querySelector('#barcode_bool'),
      barcodeText: document.querySelector('#barcode_text'),
      barcodeTop: document.querySelector('#barcode_top'),
      barcodeWidthFactor: document.querySelector('#barcode_width_factor'),
    };

    // Listen for change of text input and update Text of Variable contents
    ldState.textButtons.text.addEventListener('input', () => {
      const txtObj = resolveTextObject();
      const pre = txtObj.text();
      const post = ldState.textButtons.text.value;

      txtObj.text(ldState.textButtons.text.value);
      ldState.stage.draw();
      ldState.changesMade = true;
      UndoEngine.addCommand({
        shapeId: ldState.selectedShape._id, // eslint-disable-line no-underscore-dangle
        action: 'textChange',
        current: post,
        previous: pre,
        executeUndo() {
          const node = getTextPartById(this.shapeId);
          if (node) {
            node.text(this.previous);
            if (node === ldState.selectedShape) {
              ldState.textButtons.text.value = this.previous;
            }
            ldState.stage.draw();
          }
          console.log('UNDO', this.shapeId, this.previous);
        },
        executeRedo() {
          const node = getTextPartById(this.shapeId);
          if (node) {
            node.text(this.current);
            if (node === ldState.selectedShape) {
              ldState.textButtons.text.value = this.current;
            }
            ldState.stage.draw();
          }
          console.log('REDO', this.shapeId, this.current);
        },
      });
    });

    // Listen for change of font size
    ldState.textButtons.fontSize.addEventListener('change', () => {
      const affectedShapes = [];
      let prevState;
      let txtObj;

      if (ldState.selectedMultiple.length > 0) {
        ldState.selectedMultiple.forEach((item) => {
          txtObj = resolveTextObject(item);
          if (!prevState) {
            prevState = txtObj.fontSize();
          }
          txtObj.fontSize(Number(ldState.textButtons.fontSize.value));
          affectedShapes.push(item._id); // eslint-disable-line no-underscore-dangle
        });
      } else {
        txtObj = resolveTextObject();
        prevState = txtObj.fontSize();
        txtObj.fontSize(Number(ldState.textButtons.fontSize.value));
        affectedShapes.push(ldState.selectedShape._id); // eslint-disable-line no-underscore-dangle
      }
      ldState.stage.draw();
      ldState.changesMade = true;

      UndoEngine.addCommand({
        shapeIds: affectedShapes,
        action: 'fontSize',
        current: Number(ldState.textButtons.fontSize.value),
        previous: prevState,
        executeUndo() {
          let item;
          this.shapeIds.forEach((id) => {
            item = getTextPartById(id);
            item.fontSize(this.previous);
          });
          if ((ldState.selectedShape && this.shapeIds.includes(ldState.selectedShape._id)) // eslint-disable-line no-underscore-dangle
            || (ldState.selectedMultiple.length > 0 && ldState.selectedMultiple.some(multi => this.shapeIds.includes(multi._id)))) { // eslint-disable-line no-underscore-dangle
            ldState.textButtons.fontSize.value = this.previous;
          }
          ldState.stage.draw();
          console.log('UNDO', this.shapeIds, this.action, this.previous);
        },
        executeRedo() {
          let item;
          this.shapeIds.forEach((id) => {
            item = getTextPartById(id);
            item.fontSize(this.current);
          });
          if ((ldState.selectedShape && this.shapeIds.includes(ldState.selectedShape._id)) // eslint-disable-line no-underscore-dangle
            || (ldState.selectedMultiple.length > 0 && ldState.selectedMultiple.some(multi => this.shapeIds.includes(multi._id)))) { // eslint-disable-line no-underscore-dangle
            ldState.textButtons.fontSize.value = this.current;
          }
          ldState.stage.draw();
          console.log('REDO', this.shapeIds, this.action, this.current);
        },
      });
    });

    // Listen for change of font family
    ldState.textButtons.fontFamily.addEventListener('change', () => {
      const affectedShapes = [];
      let prevState;
      let txtObj;

      if (ldState.selectedMultiple.length > 0) {
        ldState.selectedMultiple.forEach((item) => {
          txtObj = resolveTextObject(item);
          if (!prevState) {
            prevState = txtObj.fontFamily();
          }
          txtObj.fontFamily(ldState.textButtons.fontFamily.value);
          affectedShapes.push(item._id); // eslint-disable-line no-underscore-dangle
        });
      } else {
        txtObj = resolveTextObject();
        prevState = txtObj.fontFamily();
        txtObj.fontFamily(ldState.textButtons.fontFamily.value);
        affectedShapes.push(ldState.selectedShape._id); // eslint-disable-line no-underscore-dangle
      }
      ldState.stage.draw();
      ldState.changesMade = true;

      UndoEngine.addCommand({
        shapeIds: affectedShapes,
        action: 'fontFamily',
        current: ldState.textButtons.fontFamily.value,
        previous: prevState,
        executeUndo() {
          let item;
          this.shapeIds.forEach((id) => {
            item = getTextPartById(id);
            item.fontFamily(this.previous);
          });
          if ((ldState.selectedShape && this.shapeIds.includes(ldState.selectedShape._id)) // eslint-disable-line no-underscore-dangle
            || (ldState.selectedMultiple.length > 0 && ldState.selectedMultiple.some(multi => this.shapeIds.includes(multi._id)))) { // eslint-disable-line no-underscore-dangle
            ldState.textButtons.fontFamily.value = this.previous;
          }
          ldState.stage.draw();
          console.log('UNDO', this.shapeIds, this.action, this.previous);
        },
        executeRedo() {
          let item;
          this.shapeIds.forEach((id) => {
            item = getTextPartById(id);
            item.fontFamily(this.current);
          });
          if ((ldState.selectedShape && this.shapeIds.includes(ldState.selectedShape._id)) // eslint-disable-line no-underscore-dangle
            || (ldState.selectedMultiple.length > 0 && ldState.selectedMultiple.some(multi => this.shapeIds.includes(multi._id)))) { // eslint-disable-line no-underscore-dangle
            ldState.textButtons.fontFamily.value = this.current;
          }
          ldState.stage.draw();
          console.log('REDO', this.shapeIds, this.action, this.current);
        },
      });
    });

    /*
     * Build up a compound variable when the user presses the add or clear buttons.
     */
    ldState.variableUI.compoundVars.addEventListener('click', (event) => {
      const elem = event.target.closest('[type=button]');
      if (!elem) {
        return;
      }
      if (ldState.variableUI.compoundRes.value === '') {
        ldState.variableUI.compoundRes.value = 'CMP:';
      }
      if (elem.name === 'add_compound_sel') {
        ldState.variableUI.compoundDisp.textContent += ldState.variableUI.compoundSel.selectr.getValue(true);
        ldState.variableUI.compoundRes.value += `\${${ldState.variableUI.compoundSel.selectr.getValue(true)}}`;
      }
      if (elem.name === 'add_compound_txt') {
        ldState.variableUI.compoundDisp.textContent += ldState.variableUI.compoundTxt.value;
        ldState.variableUI.compoundRes.value += ldState.variableUI.compoundTxt.value;
      }
      if (elem.name === 'clear_compound') {
        ldState.variableUI.compoundDisp.textContent = '';
        ldState.variableUI.compoundRes.value = 'CMP:';
      }
    });

    ldState.stage = new Konva.Stage({
      container: 'paper',
      width: ((labelConfig.width !== undefined) ? (labelConfig.width - 1) * labelConfig.pxPerMm : 700),
      height: ((labelConfig.height !== undefined) ? (labelConfig.height - 1) * labelConfig.pxPerMm : 500),
    });

    // Start of drag
    ldState.stage.on('dragstart', (event) => {
      if (ldState.currentMode !== 'select') {
        ldState.stage.stopDrag();
      } else if (ldState.selectedMultiple.length > 0) {
        if (!event.target.nodes) { // Use transformer
          return null;
        }
        const pos = event.target.absolutePosition();
        ldState.dragStartX = pos.x;
        ldState.dragStartY = pos.y;
      } else if (!event.target.nodes) { // Ignore when a Transformer is dragged
        const pos = event.target.absolutePosition();
        if (event.target.points) { // Lines do not have absolutePosition
          const points = event.target.points();
          pos.x = points[0];
          pos.y = points[1];
        }
        ldState.dragStartX = pos.x;
        ldState.dragStartY = pos.y;
      }
      return null;
    });

    // End of drag
    ldState.stage.on('dragend', (event) => {
      if (ldState.currentMode === 'select') {
        if (ldState.selectedMultiple.length > 0) {
          if (!event.target.nodes) {
            return null;
          }
          const pos = event.target.absolutePosition();
          const move = {
            x: pos.x - ldState.dragStartX,
            y: pos.y - ldState.dragStartY,
          };
          registerMoveUndo(ldState.selectedMultiple, move); // move amount is not accurate...
        } else {
          if (event.target.nodes) { // Ignore when a Transformer is dragged
            return null;
          }
          ldState.changesMade = true;
          const pos = event.target.absolutePosition();
          if (pos.x === 0 && pos.y === 0) {
            const points = event.target.points();
            pos.x = points[0];
            pos.y = points[1];
          }
          const move = {
            x: pos.x - ldState.dragStartX,
            y: pos.y - ldState.dragStartY,
          };
          registerMoveUndo([event.target], move);
        }
      }
      return null;
    });

    // Single shape selected
    ldState.stage.on('ldSelectOne', () => {
      document.querySelector('#send-to-back-opt').dataset.menu = 'on';
      ldState.selectedMultiple = [];
      ldState.tr.enabledAnchors(['top-left', 'top-center', 'top-right', 'middle-right', 'middle-left',
        'bottom-left', 'bottom-center', 'bottom-right']);
      setSelectedButtons(true, textTypeSelected());
      setCopyButtons(true);
      setAlignButtons(false);
      if (lineTypeSelected()) {
        setLineButtons(true);
        if (ldState.selectedShape.name() === 'line') {
          if (ldState.selectedShape.points()[0] === ldState.selectedShape.points()[2]) {
            ldState.tr.enabledAnchors(['top-center', 'bottom-center']);
          } else {
            ldState.tr.enabledAnchors(['middle-right', 'middle-left']);
          }
        }
      } else {
        setLineButtons(false);
      }
      document.querySelector('#set-variable-opt').dataset.menu = 'off';
      if (textTypeSelected()) {
        setTextButtons(true);
        if (ldState.selectedShape.name() === 'variableBox') {
          document.querySelector('#set-variable-opt').dataset.menu = 'on';
        }
      } else {
        setTextButtons(false);
      }
    });

    // Shape(s) unselected
    ldState.stage.on('ldSelectNone', () => {
      document.querySelector('#send-to-back-opt').dataset.menu = 'off';
      ldState.tr.nodes([]);
      ldState.stage.draw();
      ldState.selectedShape = undefined;
      ldState.selectedMultiple = [];
      setSelectedButtons(false);
      setLineButtons(false);
      setTextButtons(false);
      setCopyButtons(false);
      setAlignButtons(false);
      document.querySelector('#set-variable-opt').dataset.menu = 'off';
      // console.log('Selected none', ldState.selectedShape);
    });

    // Multiple shapes selected
    ldState.stage.on('ldSelectMultiple', () => {
      document.querySelector('#send-to-back-opt').dataset.menu = 'off';
      ldState.tr.enabledAnchors(['top-left', 'top-center', 'top-right', 'middle-right', 'middle-left',
        'bottom-left', 'bottom-center', 'bottom-right']);
      setSelectedButtons(false);
      setLineButtons(false);
      // setTextButtons(false); // TODO: more nuanced - depends on what shapes have in common..
      setButtonsForMultiple();
      setAlignButtons(true);
      document.querySelector('#set-variable-opt').dataset.menu = 'off';
      // console.log('Selected multiple', ldState.selectedMultiple);
    });

    // Assemble the drawing canvas
    ldState.layer = new Konva.Layer();
    ldState.layerVar = new Konva.Layer();
    // Set the drawing area's background to white.
    const konvaDiv = document.querySelector('div.konvajs-content');
    konvaDiv.classList.add('bg-white');
    ldState.tr = new Konva.Transformer({ rotateEnabled: false });
    ldState.tr.nodes([]);
    // ldState.tr.on('transformstart', (event) => {
    //   ldState.startTransform = event.target.getClientRect();
    //   // console.log('tr.start', event.target.getAbsoluteTransform());
    //   console.log('tr.startrect', ldState.tr.getClientRect());
    //   console.log('tr.starttfr', ldState.tr.getAbsoluteTransform());
    // });
    // ldState.tr.on('transformend', (event) => {
    //   console.log('tr.endrect', ldState.tr.getClientRect());
    //   console.log('tr.endtfr', ldState.tr.getAbsoluteTransform());
    //   const endTransform = event.target.getClientRect();
    //   const width = endTransform.width - ldState.startTransform.width;
    //   const height = endTransform.height - ldState.startTransform.height;
    //   const change = {
    //     width,
    //     height,
    //   };
    //   console.log('change', change);
    //
    //   UndoEngine.addCommand({
    //     shapeIds: ldState.tr.nodes().map(item => item._id), // eslint-disable-line no-underscore-dangle
    //     action: 'resize',
    //     current: change,
    //     previous: { width: change.width * -1, height: change.height * -1 },
    //     executeUndo() {
    //       let item;
    //       this.shapeIds.forEach((id) => {
    //         item = getShapeById(id);
    //         if (this.previous.width !== 0) {
    //           adjustWidth(item, this.previous.width);
    //         }
    //         if (this.previous.height !== 0) {
    //           adjustHeight(item, this.previous.height);
    //         }
    //       });
    //       ldState.stage.draw();
    //       console.log('UNDO', this.shapeIds, this.previous);
    //     },
    //     executeRedo() {
    //       let item;
    //       this.shapeIds.forEach((id) => {
    //         item = getShapeById(id);
    //         if (this.current.width !== 0) {
    //           adjustWidth(item, this.current.width);
    //         }
    //         if (this.current.height !== 0) {
    //           adjustHeight(item, this.current.height);
    //         }
    //       });
    //       ldState.stage.draw();
    //       console.log('REDO', this.shapeIds, this.current);
    //     },
    //   });
    //   // console.log('tr.end', event.target.getAbsoluteTransform());
    //   // console.log('tr.endrect', event.target.getClientRect());
    // });
    ldState.layer.add(ldState.tr);
    ldState.stage.add(ldState.layer);
    ldState.stage.add(ldState.layerVar);

    // Listen for select/unselect in the canvas stage
    ldState.stage.on('click tap', (e) => {
      // if click on empty area - remove all selections
      if (e.target === ldState.stage) {
        if (ldState.tr.nodes().length > 1) {
          setNodeSelectionColours(false, ldState.tr.nodes());
        }
        ldState.stage.fire('ldSelectNone');
        return;
      }

      let target = e.target;
      const parentGroup = target.findAncestor('Group');
      if (parentGroup) {
        target = parentGroup;
      }

      // did we press shift or ctrl?
      const metaPressed = e.evt.shiftKey || e.evt.ctrlKey || e.evt.metaKey;
      const isSelected = ldState.tr.nodes().indexOf(target) >= 0;

      ldState.selectedShape = undefined;
      if (!metaPressed && !isSelected) {
        // if no key pressed and the node is not selected
        // select just one
        if (ldState.tr.nodes().length > 1) {
          setNodeSelectionColours(false, ldState.tr.nodes());
        }
        ldState.tr.nodes([target]);
        ldState.selectedShape = target;
        ldState.stage.fire('ldSelectOne');
      } else if (metaPressed && isSelected) {
        if (ldState.tr.nodes().length > 1) {
          setNodeSelectionColours(false, ldState.tr.nodes());
        }
        // if we pressed keys and node was selected
        // we need to remove it from selection:
        const nodes = ldState.tr.nodes().slice(); // use slice to have new copy of array
        // remove node from array
        nodes.splice(nodes.indexOf(target), 1);
        ldState.tr.nodes(nodes);
        if (nodes.length === 1) {
          ldState.selectedShape = nodes[0];
          ldState.stage.fire('ldSelectOne');
        } else {
          ldState.selectedMultiple = nodes;
          setNodeSelectionColours(true, ldState.tr.nodes());
          ldState.stage.fire('ldSelectMultiple');
        }
      } else if (metaPressed && !isSelected) {
        // add the node into selection
        const nodes = ldState.tr.nodes().concat([target]);
        ldState.tr.nodes(nodes);
        ldState.selectedMultiple = nodes;
        setNodeSelectionColours(true, ldState.tr.nodes());
        ldState.stage.fire('ldSelectMultiple');
      }
      ldState.layer.draw();
      ldState.layerVar.draw();
    });

    // Listen for context menu event in the canvas stage
    ldState.stage.on('contextmenu', (e) => {
      // prevent default behavior
      e.evt.preventDefault();
      if (e.target === ldState.stage) {
        // if we are on empty place of the stage we will do nothing
        menuNode.style.display = 'none';
        return;
      }
      if (ldState.selectedMultiple.length > 0) {
        return;
      }
      const parentGroup = e.target.findAncestor('Group');
      if (!parentGroup || parentGroup.name() !== 'variableBox') {
        document.querySelectorAll('[data-filter="variable"]').forEach(elem => elem.hidden = true);
      } else {
        document.querySelectorAll('[data-filter="variable"]').forEach(elem => elem.hidden = false);
      }

      // Make selection
      if (parentGroup) {
        ldState.tr.nodes([parentGroup]);
        ldState.selectedShape = parentGroup;
      } else {
        ldState.tr.nodes([e.target]);
        ldState.selectedShape = e.target;
      }
      ldState.stage.draw();
      ldState.stage.fire('ldSelectOne');

      // show menu
      menuNode.style.display = 'initial';
      menuNode.style.top = `${ldState.stage.getPointerPosition().y + 4}px`;
      menuNode.style.left = `${ldState.stage.getPointerPosition().x + 4}px`;
    });
  };

  const ldCanvas = document.getElementById('paper');

  // When save is pressed in the variable dialog - save settings to the shape
  const saveVariableSettings = (variableTypeValue) => {
    // For undo/redo, save the varAttrs, text, varType, txt.fill & rect.stroke
    const txtObj = ldState.selectedShape.getChildren(node => node.getClassName() === 'Text')[0];
    const rectObj = ldState.selectedShape.getChildren(node => node.getClassName() === 'Rect')[0];
    const prevState = {
      varAttrs: ldState.selectedShape.attrs.varAttrs,
      varType: ldState.selectedShape.attrs.varType,
      text: txtObj.text(),
      fill: txtObj.fill(),
      stroke: rectObj.stroke(),
    };

    const varAttrs = {
      whiteOnBlack: ldState.variableUI.whiteOnBlack.checked,
      barcode: ldState.variableUI.barcodeBool.checked,
      barcodeText: ldState.variableUI.barcodeText.checked,
      barcodeTop: ldState.variableUI.barcodeTop.value,
      barcodeWidthFactor: ldState.variableUI.barcodeWidthFactor.value,
      barcodeSymbology: ldState.variableUI.barcodeSymbology.value,
      staticValue: variableTypeValue === 'Static Barcode' ? ldState.variableUI.staticInputValue.value : null,
    };
    if (txtObj.text() === 'Unset Variable' || ldState.selectedShape.attrs.varType === txtObj.text()) {
      txtObj.text(variableTypeValue);
      ldState.textButtons.text.value = variableTypeValue;
    }
    if (variableTypeValue === 'Compound Variable') {
      ldState.selectedShape.attrs.varType = ldState.variableUI.compoundRes.value;
    } else {
      ldState.selectedShape.attrs.varType = variableTypeValue;
    }
    ldState.selectedShape.attrs.varAttrs = varAttrs;
    if (varAttrs.whiteOnBlack) {
      txtObj.fill('#CA48BC');
      rectObj.stroke('#CA48BC');
    } else if (varAttrs.barcode) {
      txtObj.fill('#9E3B00');
      rectObj.stroke('#9E3B00');
    } else {
      txtObj.fill('black');
      rectObj.stroke('#188FA7');
    }
    ldState.stage.draw();
    ldState.changesMade = true;

    const newState = {
      varAttrs,
      varType: ldState.selectedShape.attrs.varType,
      text: txtObj.text(),
      fill: txtObj.fill(),
      stroke: rectObj.stroke(),
    };

    UndoEngine.addCommand({
      shapeId: ldState.selectedShape._id, // eslint-disable-line no-underscore-dangle
      action: 'setVars',
      current: newState,
      previous: prevState,
      executeUndo() {
        const item = getShapeById(this.shapeId);
        const txtItem = item.getChildren(node => node.getClassName() === 'Text')[0];
        const rectItem = item.getChildren(node => node.getClassName() === 'Rect')[0];
        item.attrs.varAttrs = this.previous.varAttrs;
        item.attrs.varType = this.previous.varType;
        txtItem.text(this.previous.text);
        txtItem.fill(this.previous.fill);
        rectItem.stroke(this.previous.stroke);
        ldState.stage.draw();
        console.log('UNDO', this.shapeId, this.action, this.previous);
      },
      executeRedo() {
        const item = getShapeById(this.shapeId);
        const txtItem = item.getChildren(node => node.getClassName() === 'Text')[0];
        const rectItem = item.getChildren(node => node.getClassName() === 'Rect')[0];
        item.attrs.varAttrs = this.current.varAttrs;
        item.attrs.varType = this.current.varType;
        txtItem.text(this.current.text);
        txtItem.fill(this.current.fill);
        rectItem.stroke(this.current.stroke);
        ldState.stage.draw();
        console.log('REDO', this.shapeId, this.action, this.current);
      },
    });
  };

  // Variable dialog: toggle barcode options
  const toggleBarcodeOptions = (checked) => {
    if (checked) {
      ldState.variableUI.whiteOnBlack.checked = false;
      ldState.variableUI.whiteOnBlack.disabled = true;
      ldState.variableUI.barcodeOptions.style.display = 'block';
    } else {
      ldState.variableUI.whiteOnBlack.disabled = false;
      ldState.variableUI.barcodeOptions.style.display = 'none';
    }
  };

  // Variable dialog: toggle error display
  const toggleErrorNotice = (show) => {
    if (show) {
      ldState.variableUI.errBox.style.display = 'block';
    } else {
      ldState.variableUI.errBox.style.display = 'none';
    }
  };

  const clearCompoundTexts = () => {
    ldState.variableUI.compoundTxt.value = '';
    ldState.variableUI.compoundSel.selectr.setChoiceByValue('');
    ldState.variableUI.compoundRes.value = 'CMP:';
    ldState.variableUI.compoundDisp.textContent = '';
  };

  // On dialog save pressed, validate inputs and call save action
  const dialogSaveButton = () => {
    const noVarErr = 'Please ensure that a Variable type is saved';
    const noStaticErr = 'Please fill in text for a Static Barcode';
    const variableTypeValue = ldState.variableUI.variableSelect.selectr.getValue(true);

    // console.log(variableTypeValue);
    if (variableTypeValue) {
      if (variableTypeValue === 'Static Barcode' && ldState.variableUI.staticInputValue.value === '') {
        ldState.variableUI.errBox.textContent = noStaticErr;
        toggleErrorNotice(true);
      } else {
        saveVariableSettings(variableTypeValue);

        ldState.variableUI.varDialog.hide();
        toggleErrorNotice(false);
      }
    } else {
      ldState.variableUI.errBox.textContent = noVarErr;
      toggleErrorNotice(true);
    }
  };

  // Listen to changes in variable selection
  const varChange = (value) => {
    if (value === 'Static Barcode') {
      ldState.variableUI.staticInput.style.display = 'flex';
      ldState.variableUI.staticInputValue.required = true;
      ldState.variableUI.barcodeBool.checked = true;
      toggleBarcodeOptions(true);
      ldState.variableUI.barcodeBool.disabled = true;
      ldState.variableUI.barcodeBoolWrapper.hidden = false;
      ldState.variableUI.compoundVars.hidden = true;
      clearCompoundTexts();
    } else if (value === 'Compound Variable') {
      ldState.variableUI.staticInputValue.required = false;
      ldState.variableUI.staticInput.style.display = 'none';
      ldState.variableUI.barcodeBool.disabled = false;
      ldState.variableUI.barcodeBool.checked = false;
      ldState.variableUI.barcodeBoolWrapper.hidden = true;
      toggleBarcodeOptions(false);
      ldState.variableUI.compoundVars.hidden = false;
    } else {
      ldState.variableUI.staticInputValue.required = false;
      ldState.variableUI.staticInput.style.display = 'none';
      ldState.variableUI.barcodeBool.disabled = false;
      ldState.variableUI.barcodeBoolWrapper.hidden = false;
      ldState.variableUI.compoundVars.hidden = true;
      clearCompoundTexts();
    }
  };

  const shapeForClipboard = (shape) => {
    const marshal = new LdMarshal(shape);
    return marshal.dump();
  };

  const copyToClipboard = () => {
    ldState.clipboard = { shapes: [] };
    ldState.copyOffset = 5;

    if (ldState.selectedShape) {
      ldState.clipboard.shapes.push(shapeForClipboard(ldState.selectedShape));
    } else {
      ldState.selectedMultiple.forEach((elem) => {
        ldState.clipboard.shapes.push(shapeForClipboard(elem));
      });
    }
    document.querySelector('[data-action="paste"]').disabled = false;
  };

  const pasteFromClipboard = () => {
    const newSelection = [];
    let marshal;
    const undos = [];
    if (ldState.tr.nodes().length > 1) {
      setNodeSelectionColours(false, ldState.tr.nodes());
    }

    ldState.clipboard.shapes.forEach((shape) => {
      marshal = new LdMarshal(shape);
      newSelection.push(marshal.load(ldState.copyOffset));
      marshal = new LdMarshal(newSelection[newSelection.length - 1]);
      undos.push(marshal.dump());
    });
    ldState.copyOffset += 5;
    if (ldState.tr.nodes().length > 1) {
      setNodeSelectionColours(false, ldState.tr.nodes());
    }
    if (newSelection.length === 1) {
      ldState.currentMode = 'select';
      ldState.tr.nodes(newSelection);
      ldState.selectedShape = newSelection[0];
    } else {
      ldState.tr.nodes(newSelection);
      ldState.selectedMultiple = newSelection;
    }
    if (ldState.tr.nodes().length > 1) {
      setNodeSelectionColours(true, ldState.tr.nodes());
    }
    ldState.stage.draw();

    UndoEngine.addCommand({
      shapeIds: newSelection.map(item => item._id), // eslint-disable-line no-underscore-dangle
      action: 'paste',
      current: undos,
      previous: null,
      executeUndo() {
        let item;
        if (ldState.tr.nodes().length > 1) {
          setNodeSelectionColours(false, ldState.tr.nodes());
        }
        this.shapeIds.forEach((id) => {
          item = getShapeById(id);
          if (ldState.tr.nodes().includes(item)) {
            const nodes = ldState.tr.nodes().slice(); // use slice to have new copy of array
            // remove node from array
            nodes.splice(nodes.indexOf(item), 1);
            ldState.tr.nodes(nodes);
          }
          item.destroy();
        });
        if (ldState.tr.nodes().length > 1) {
          setNodeSelectionColours(true, ldState.tr.nodes());
        }
        ldState.stage.draw();
        console.log('UNDO', this.shapeIds, this.action, this.previous);
      },
      executeRedo() {
        let item;
        const newIds = [];
        if (ldState.tr.nodes().length > 1) {
          setNodeSelectionColours(false, ldState.tr.nodes());
        }
        this.current.forEach((node, idx) => {
          marshal = new LdMarshal(node);
          item = marshal.load();
          UndoEngine.replaceId(this.shapeIds[idx], item._id); // eslint-disable-line no-underscore-dangle
          newIds.push(item._id); // eslint-disable-line no-underscore-dangle
        });
        if (ldState.tr.nodes().length > 1) {
          setNodeSelectionColours(true, ldState.tr.nodes());
        }
        ldState.stage.draw();
        this.shapeIds = newIds;
        console.log('REDO', this.shapeIds, this.action, this.current);
      },
    });
  };

  // De-select any shapes and return a png copy of all shapes except those on the variable layer
  const getBackgroundImage = () => {
    if (ldState.tr.nodes().length > 1) {
      setNodeSelectionColours(false, ldState.tr.nodes());
    }
    ldState.tr.nodes([]);
    ldState.stage.draw();
    ldState.stage.fire('ldSelectNone');
    return ldState.layer.toDataURL();
  };

  const showVariableDialog = () => {
    const curr = ldState.selectedShape.attrs.varAttrs;
    const varType = ldState.selectedShape.attrs.varType.indexOf('CMP:') === 0 ? 'Compound Variable' : ldState.selectedShape.attrs.varType;

    ldState.variableUI.varDialog.show();
    ldState.variableUI.varForm.reset();
    ldState.variableUI.variableSelect.selectr.setChoiceByValue(varType === 'unset' ? '' : varType);

    ldState.variableUI.whiteOnBlack.checked = curr.whiteOnBlack;
    ldState.variableUI.barcodeBool.checked = curr.barcode;
    ldState.variableUI.barcodeText.checked = curr.barcodeText;
    ldState.variableUI.barcodeTop.value = curr.barcodeTop;
    ldState.variableUI.barcodeWidthFactor.value = curr.barcodeWidthFactor;
    ldState.variableUI.barcodeSymbology.value = curr.barcodeSymbology;
    ldState.variableUI.staticInputValue.value = curr.staticValue ? curr.staticValue : '';

    // Set the UI barcode show/hide state
    varChange(varType);
    toggleBarcodeOptions(curr.barcode);
  };

  const deleteShape = (shape) => {
    let marshal = new LdMarshal(shape);
    const prevState = marshal.dump();
    const prevId = shape._id; // eslint-disable-line no-underscore-dangle

    shape.destroy();
    ldState.stage.fire('ldSelectNone');
    ldState.changesMade = true;

    UndoEngine.addCommand({
      shapeId: prevId,
      action: 'delete',
      current: null,
      previous: prevState,
      executeUndo() {
        marshal = new LdMarshal(prevState);
        const item = marshal.load();
        UndoEngine.replaceId(this.shapeId, item._id); // eslint-disable-line no-underscore-dangle
        ldState.stage.draw();
        console.log('UNDO', this.shapeId, this.action, this.previous);
      },
      executeRedo() {
        const item = getShapeById(this.shapeId);
        item.destroy();
        ldState.stage.draw();
        console.log('REDO', this.shapeId, this.action, this.current);
      },
    });
  };

  // --- START OF CONTEXT MENU
  document.getElementById('set-variable').addEventListener('click', () => {
    showVariableDialog();
  });
  document.getElementById('send-to-back').addEventListener('click', () => {
    ldState.selectedShape.moveToBottom();
  });

  window.addEventListener('click', () => {
    // hide menu
    menuNode.style.display = 'none';
  });
  // --- END OF CONTEXT MENU

  document.addEventListener('DOMContentLoaded', () => {
    // Make the variable select a Choices dropdown
    const holdSel = new Choices(ldState.variableUI.variableSelect, {
      searchEnabled: true,
      searchResultLimit: 100,
      removeItemButton: false,
      renderSelectedChoices: 'always',
      itemSelectText: '',
      classNames: {
        containerOuter: 'choices cbl-input',
        containerInner: 'choices__inner_cbl',
        highlightedState: 'is-highlighted_cbl',
      },
      shouldSort: false,
      searchFields: ['label'],
      fuseOptions: {
        include: 'score',
        threshold: 0.25,
      },
    });
    // Store a reference on the DOM node.
    ldState.variableUI.variableSelect.selectr = holdSel;

    ldState.variableUI.variableSelect.addEventListener('change', (event) => {
      varChange(event.detail.value);
    });

    // Make the compound variable select a Choices dropdown
    const holdCmpSel = new Choices(ldState.variableUI.compoundSel, {
      searchEnabled: true,
      searchResultLimit: 100,
      removeItemButton: true,
      itemSelectText: '',
      classNames: {
        containerOuter: 'choices cbl-input',
        containerInner: 'choices__inner_cbl',
        highlightedState: 'is-highlighted_cbl',
      },
      shouldSort: false,
      searchFields: ['label'],
      fuseOptions: {
        include: 'score',
        threshold: 0.25,
      },
    });
    // Store a reference on the DOM node.
    ldState.variableUI.compoundSel.selectr = holdCmpSel;

    document.querySelector('#variable-info-dialog-form button.save').addEventListener('click', () => {
      dialogSaveButton();
    });

    ldState.variableUI.barcodeBool.addEventListener('change', function barcodeChange() {
      toggleBarcodeOptions(this.checked);
    });

    document.querySelector('.btn-download-image').addEventListener('click', () => {
      const href = getBackgroundImage();
      document.querySelector('#btn-download-image').href = href;
    });

    document.querySelector('#set-variable-opt').addEventListener('click', (event) => {
      event.preventDefault();
      showVariableDialog();
    });

    document.querySelector('#send-to-back-opt').addEventListener('click', (event) => {
      ldState.selectedShape.moveToBottom();
      event.preventDefault();
    });

    document.addEventListener('keydown', (event) => {
      let move;
      let width;
      let height;
      let points;

      if (event.target.id === 'textinput') {
        return null;
      }

      // if dialog showing, quit
      if (event.target.closest('.dialog-content')) {
        return null;
      }

      // Undo/Redo
      if (event.key === 'z' && event.ctrlKey && !document.querySelector('[data-action="undo"]').disabled) {
        UndoEngine.undo();
        if (!UndoEngine.canUndo()) {
          ldState.changesMade = false;
        }
      }
      if (event.key === 'y' && event.ctrlKey && !document.querySelector('[data-action="redo"]').disabled) {
        UndoEngine.redo();
        ldState.changesMade = true;
      }

      // Paste
      if (event.key === 'v' && event.ctrlKey && !document.querySelector('[data-action="paste"]').disabled) {
        pasteFromClipboard();
        ldState.changesMade = true;
      }

      // The rest of the actions depend on selected shape(s).
      if (!ldState.selectedShape && !ldState.selectedMultiple.length > 0) {
        return null;
      }

      // Copy
      if (event.key === 'c' && event.ctrlKey && !document.querySelector('[data-action="copy"]').disabled) {
        copyToClipboard();
      }

      // Delete (Remove)
      if (event.key === 'Delete' && ldState.selectedShape) {
        deleteShape(ldState.selectedShape);
      }

      // Move and resize
      if (event.key === 'ArrowUp') {
        if (event.ctrlKey) {
          height = -1;
        } else {
          move = { x: 0, y: -1 };
        }
      }
      if (event.key === 'ArrowDown') {
        if (event.ctrlKey) {
          height = 1;
        } else {
          move = { x: 0, y: 1 };
        }
      }
      if (event.key === 'ArrowLeft') {
        if (event.ctrlKey) {
          width = -1;
        } else {
          move = { x: -1, y: 0 };
        }
      }
      if (event.key === 'ArrowRight') {
        if (event.ctrlKey) {
          width = 1;
        } else {
          move = { x: 1, y: 0 };
        }
      }

      // Apply move
      if (move) {
        if (ldState.selectedMultiple.length > 0) {
          ldState.selectedMultiple.forEach((elem) => {
            if (elem.name() === 'line') {
              points = elem.points();
              elem.points([points[0] + move.x, points[1] + move.y, points[2] + move.x, points[3] + move.y]);
            } else {
              elem.move(move);
            }
          });
          registerMoveUndo(ldState.selectedMultiple, move);
        } else if (ldState.selectedShape.name() === 'line') {
          points = ldState.selectedShape.points();
          ldState.selectedShape.points([points[0] + move.x, points[1] + move.y, points[2] + move.x, points[3] + move.y]);
          registerMoveUndo([ldState.selectedShape], move);
        } else {
          ldState.selectedShape.move(move);
          registerMoveUndo([ldState.selectedShape], move);
        }
        ldState.changesMade = true;
      }

      // Apply Resize
      if (width) {
        if (ldState.selectedMultiple.length > 0) {
          ldState.selectedMultiple.forEach((elem) => {
            adjustWidth(elem, width);
          });
        } else {
          adjustWidth(ldState.selectedShape, width);
        }
      }
      if (height) {
        if (ldState.selectedMultiple.length > 0) {
          ldState.selectedMultiple.forEach((elem) => {
            adjustHeight(elem, height);
          });
        } else {
          adjustHeight(ldState.selectedShape, height);
        }
      }
      if (width || height) {
        let affectedShapes = [];
        if (ldState.selectedMultiple.length > 0) {
          affectedShapes = ldState.selectedMultiple.map(item => item._id); // eslint-disable-line no-underscore-dangle
        } else {
          affectedShapes.push(ldState.selectedShape._id); // eslint-disable-line no-underscore-dangle
        }
        const change = {
          width: width || 0,
          height: height || 0,
        };
        // register undo
        UndoEngine.addCommand({
          shapeIds: affectedShapes,
          action: 'resize',
          current: change,
          previous: { width: change.width * -1, height: change.height * -1 },
          executeUndo() {
            let item;
            this.shapeIds.forEach((id) => {
              item = getShapeById(id);
              if (this.previous.width !== 0) {
                adjustWidth(item, this.previous.width);
              }
              if (this.previous.height !== 0) {
                adjustHeight(item, this.previous.height);
              }
            });
            ldState.stage.draw();
            console.log('UNDO', this.shapeIds, this.previous);
          },
          executeRedo() {
            let item;
            this.shapeIds.forEach((id) => {
              item = getShapeById(id);
              if (this.current.width !== 0) {
                adjustWidth(item, this.current.width);
              }
              if (this.current.height !== 0) {
                adjustHeight(item, this.current.height);
              }
            });
            ldState.stage.draw();
            console.log('REDO', this.shapeIds, this.current);
          },
        });
      }

      if (move || width || height) {
        ldState.stage.draw();
        event.stopPropagation();
        event.preventDefault();
      }

      return null;
    });

    document.addEventListener('mousemove', (event) => {
      // Positioner.updateMarkers(event);
      const coords = getCoords(event);
      updateDisplay(coords);
      updateTopMarker(coords);
      updateLeftMarker(coords);
    });

    // Listen for click event on toolbar buttons
    document.addEventListener('click', (event) => {
      let btn = event.target.closest('button[data-action]');
      let enable;
      const affectedShapes = [];
      let prevState;

      // On Chrome, this event will fire even if the button is disabled...
      if (btn && !btn.disabled) {
        if (btn.dataset.active) {
          document.querySelectorAll('[data-active]').forEach(elem => elem.dataset.active = 'false');
          btn.dataset.active = 'true';
        }
        if (btn.dataset.drawType) {
          ldState.currentMode = 'draw';
          ldState.currentDrawType = btn.dataset.drawType;
        } else {
          ldState.currentMode = 'select';
          ldState.currentDrawType = undefined;
        }
        if (btn.dataset.action === 'rotate' && ldState.selectedShape) {
          ldState.selectedShape.rotate(90);
          ldState.stage.draw();
          ldState.changesMade = true;

          UndoEngine.addCommand({
            shapeId: ldState.selectedShape._id, // eslint-disable-line no-underscore-dangle
            action: 'rotate',
            current: 90,
            previous: -90,
            executeUndo() {
              const node = getShapeById(this.shapeId);
              node.rotate(this.previous);
              ldState.stage.draw();
              console.log('UNDO', this.shapeId, this.previous);
            },
            executeRedo() {
              const node = getTextPartById(this.shapeId);
              node.rotate(this.current);
              ldState.stage.draw();
              console.log('REDO', this.shapeId, this.current);
            },
          });
        }
        if (btn.dataset.action === 'remove' && ldState.selectedShape) {
          deleteShape(ldState.selectedShape);
        }
        if (btn.dataset.action === 'copy' && (ldState.selectedShape || ldState.selectedMultiple.length > 0)) {
          copyToClipboard();
        }
        if (btn.dataset.action === 'paste') {
          pasteFromClipboard();
          ldState.changesMade = true;
        }
        if (btn.dataset.action === 'undo') {
          UndoEngine.undo();
          if (!UndoEngine.canUndo()) {
            ldState.changesMade = false;
          }
        }
        if (btn.dataset.action === 'redo') {
          UndoEngine.redo();
          ldState.changesMade = true;
        }
        if (btn.dataset.image) {
          ldState.imgUpDialog.show();
        }
      }

      btn = event.target.closest('button[data-textstyle]');
      if (btn && !btn.disabled) {
        enable = btn.dataset.selected === 'false';
        btn.dataset.selected = enable;
        if (ldState.selectedMultiple.length > 0) {
          ldState.selectedMultiple.forEach((item) => {
            applyTextStyle(enable, btn.dataset.textstyle, item);
            affectedShapes.push(item._id); // eslint-disable-line no-underscore-dangle
          });
        } else {
          applyTextStyle(enable, btn.dataset.textstyle);
          affectedShapes.push(ldState.selectedShape._id); // eslint-disable-line no-underscore-dangle
        }

        UndoEngine.addCommand({
          shapeIds: affectedShapes,
          action: btn.dataset.textstyle,
          button: btn,
          current: enable,
          previous: !enable,
          executeUndo() {
            let item;
            this.shapeIds.forEach((id) => {
              item = getShapeById(id);
              applyTextStyle(this.previous, this.action, item);
            });
            if ((ldState.selectedShape && this.shapeIds.includes(ldState.selectedShape._id)) // eslint-disable-line no-underscore-dangle
              || (ldState.selectedMultiple.length > 0 && ldState.selectedMultiple.some(multi => this.shapeIds.includes(multi._id)))) { // eslint-disable-line no-underscore-dangle
              this.button.dataset.selected = this.previous;
            }
            ldState.stage.draw();
            console.log('UNDO', this.shapeIds, this.action, this.previous);
          },
          executeRedo() {
            let item;
            this.shapeIds.forEach((id) => {
              item = getShapeById(id);
              applyTextStyle(this.current, this.action, item);
            });
            if ((ldState.selectedShape && this.shapeIds.includes(ldState.selectedShape._id)) // eslint-disable-line no-underscore-dangle
              || (ldState.selectedMultiple.length > 0 && ldState.selectedMultiple.some(multi => this.shapeIds.includes(multi._id)))) { // eslint-disable-line no-underscore-dangle
              this.button.dataset.selected = this.current;
            }
            ldState.stage.draw();
            console.log('REDO', this.shapeIds, this.action, this.current);
          },
        });
        ldState.stage.draw();
        ldState.changesMade = true;
      }

      btn = event.target.closest('button[data-alignment]');
      if (btn && !btn.disabled) {
        document.querySelectorAll('button[data-alignment]').forEach((elem) => {
          if (elem.dataset.selected === 'true') {
            prevState = elem.dataset.alignment;
          }
          elem.dataset.selected = 'false';
        });
        btn.dataset.selected = 'true';
        if (ldState.selectedMultiple.length > 0) {
          ldState.selectedMultiple.forEach((item) => {
            applyTextAlignment(btn.dataset.alignment, item);
            affectedShapes.push(item._id); // eslint-disable-line no-underscore-dangle
          });
        } else {
          applyTextAlignment(btn.dataset.alignment);
          affectedShapes.push(ldState.selectedShape._id); // eslint-disable-line no-underscore-dangle
        }
        UndoEngine.addCommand({
          shapeIds: affectedShapes,
          action: 'alignText',
          // button: btn,
          current: btn.dataset.alignment,
          previous: prevState,
          executeUndo() {
            let item;
            this.shapeIds.forEach((id) => {
              item = getShapeById(id);
              applyTextAlignment(this.previous, item);
            });
            if ((ldState.selectedShape && this.shapeIds.includes(ldState.selectedShape._id)) // eslint-disable-line no-underscore-dangle
              || (ldState.selectedMultiple.length > 0 && ldState.selectedMultiple.some(multi => this.shapeIds.includes(multi._id)))) { // eslint-disable-line no-underscore-dangle
              document.querySelectorAll('button[data-alignment]').forEach((elem) => {
                elem.dataset.selected = 'false';
                if (elem.dataset.alignment === this.previous) {
                  elem.dataset.selected = 'true';
                }
              });
            }
            ldState.stage.draw();
            console.log('UNDO', this.shapeIds, this.action, this.previous);
          },
          executeRedo() {
            let item;
            this.shapeIds.forEach((id) => {
              item = getShapeById(id);
              applyTextAlignment(this.current, item);
            });
            if ((ldState.selectedShape && this.shapeIds.includes(ldState.selectedShape._id)) // eslint-disable-line no-underscore-dangle
              || (ldState.selectedMultiple.length > 0 && ldState.selectedMultiple.some(multi => this.shapeIds.includes(multi._id)))) { // eslint-disable-line no-underscore-dangle
              document.querySelectorAll('button[data-alignment]').forEach((elem) => {
                elem.dataset.selected = 'false';
                if (elem.dataset.alignment === this.current) {
                  elem.dataset.selected = 'true';
                }
              });
            }
            ldState.stage.draw();
            console.log('REDO', this.shapeIds, this.action, this.current);
          },
        });
        ldState.stage.draw();
        ldState.changesMade = true;
      }
    });
  });

  const getSelectedShape = () => ldState.selectedShape;

  const getSelectedMultiple = () => ldState.selectedMultiple;

  // For multiselect alignment: if a shape has been rotated, adjust the x/y point to something that makes beter visual sense.
  const resolveRotatedPoint = (edge, shape) => {
    if (edge === 'left') {
      if (!shape.rotation()) {
        return shape.x();
      }
      if (shape.rotation() === 0 || shape.rotation() === 270) {
        return shape.x();
      }
      if (shape.rotation() === 90) {
        return shape.x() - shape.height();
      }
      if (shape.rotation() === 180) {
        return shape.x() - shape.width();
      }
    }
    if (!shape.rotation()) {
      return shape.y();
    }
    if (shape.rotation() === 0) {
      return shape.y();
    }
    if (shape.rotation() === 0 || shape.rotation() === 90) {
      return shape.y();
    }
    if (shape.rotation() === 180) {
      return shape.y() - shape.height();
    }
    return shape.y() - shape.width();
  };

  // Align shapes along top or left edges
  const align = (edge) => {
    let startPoint;
    const undoCmds = [];
    let cmd;

    if (ldState.selectedMultiple.length === 0) {
      return 'Multiple shapes have not been selected';
    }

    if (edge === 'left') {
      if (ldState.selectedMultiple[0].name() === 'line') {
        startPoint = ldState.selectedMultiple[0].points()[0];
      } else if (ldState.selectedMultiple[0].name() === 'ellipse') {
        startPoint = ldState.selectedMultiple[0].x() - ldState.selectedMultiple[0].radiusX();
      } else {
        startPoint = resolveRotatedPoint(edge, ldState.selectedMultiple[0]);
      }
      for (let i = 1; i < ldState.selectedMultiple.length; i += 1) {
        if (ldState.selectedMultiple[i].name() === 'line') {
          const points = ldState.selectedMultiple[i].points();
          cmd = { id: ldState.selectedMultiple[i]._id, line: true, from: points.slice() }; // eslint-disable-line no-underscore-dangle
          const shift = points[0] - startPoint;
          points[0] = startPoint;
          points[2] -= shift;

          cmd.to = points;
          undoCmds.push(cmd);
          ldState.selectedMultiple[i].points(points);
        } else if (ldState.selectedMultiple[i].name() === 'ellipse') {
          cmd = {
            id: ldState.selectedMultiple[i]._id, // eslint-disable-line no-underscore-dangle
            line: false,
            move: { x: (startPoint - (ldState.selectedMultiple[i].x() - ldState.selectedMultiple[i].radiusX())), y: 0 },
          };
          undoCmds.push(cmd);
          ldState.selectedMultiple[i].move({ x: (startPoint - (ldState.selectedMultiple[i].x() - ldState.selectedMultiple[i].radiusX())), y: 0 });
        } else {
          cmd = {
            id: ldState.selectedMultiple[i]._id, // eslint-disable-line no-underscore-dangle
            line: false,
            move: { x: (startPoint - resolveRotatedPoint(edge, ldState.selectedMultiple[i])), y: 0 },
          };
          undoCmds.push(cmd);
          ldState.selectedMultiple[i].move({ x: (startPoint - resolveRotatedPoint(edge, ldState.selectedMultiple[i])), y: 0 });
        }
      }
      ldState.stage.draw();
      ldState.changesMade = true;
    }

    if (edge === 'top') {
      if (ldState.selectedMultiple[0].name() === 'line') {
        startPoint = ldState.selectedMultiple[0].points()[1];
      } else if (ldState.selectedMultiple[0].name() === 'ellipse') {
        startPoint = ldState.selectedMultiple[0].y() - ldState.selectedMultiple[0].radiusY();
      } else {
        startPoint = resolveRotatedPoint(edge, ldState.selectedMultiple[0]);
      }
      for (let i = 1; i < ldState.selectedMultiple.length; i += 1) {
        if (ldState.selectedMultiple[i].name() === 'line') {
          const points = ldState.selectedMultiple[i].points();
          cmd = { id: ldState.selectedMultiple[i]._id, line: true, from: points.slice() }; // eslint-disable-line no-underscore-dangle
          const shift = points[1] - startPoint;
          points[1] = startPoint;
          points[3] -= shift;
          cmd.to = points;
          undoCmds.push(cmd);
          ldState.selectedMultiple[i].points(points);
        } else if (ldState.selectedMultiple[i].name() === 'ellipse') {
          cmd = {
            id: ldState.selectedMultiple[i]._id, // eslint-disable-line no-underscore-dangle
            line: false,
            move: { x: 0, y: (startPoint - (ldState.selectedMultiple[i].y() - ldState.selectedMultiple[i].radiusY())) },
          };
          undoCmds.push(cmd);
          ldState.selectedMultiple[i].move({ x: 0, y: (startPoint - (ldState.selectedMultiple[i].y() - ldState.selectedMultiple[i].radiusY())) });
        } else {
          cmd = {
            id: ldState.selectedMultiple[i]._id, // eslint-disable-line no-underscore-dangle
            line: false,
            move: { x: 0, y: (startPoint - resolveRotatedPoint(edge, ldState.selectedMultiple[i])) },
          };
          undoCmds.push(cmd);
          ldState.selectedMultiple[i].move({ x: 0, y: (startPoint - resolveRotatedPoint(edge, ldState.selectedMultiple[i])) });
        }
      }
      ldState.stage.draw();
      ldState.changesMade = true;
    }

    UndoEngine.addCommand({
      // shapeId: recttmp._id, // eslint-disable-line no-underscore-dangle
      action: 'align',
      changes: undoCmds,
      executeUndo() {
        let item;
        let move;
        this.changes.forEach((change) => {
          item = getShapeById(change.id);
          if (change.line) {
            item.points(change.from);
          } else {
            move = { x: change.move.x * -1, y: change.move.y * -1 };
            item.move(move);
          }
        });
        ldState.stage.draw();
        console.log('UNDO', this.action, this.changes);
      },
      executeRedo() {
        let item;
        this.changes.forEach((change) => {
          item = getShapeById(change.id);
          if (change.line) {
            item.points(change.to);
          } else {
            item.move(change.move);
          }
        });
        ldState.stage.draw();
        console.log('REDO', this.action, this.changes);
      },
    });
    return null;
  };

  const getCurrentMode = () => ldState.currentMode;

  const getCurrentDrawType = () => ldState.currentDrawType;

  // Draw a new shape on end of drag event
  const drawNew = (x, y, x2, y2) => {
    let recttmp;
    let shape;
    let startX = x;
    let startY = y;
    let endX = x2;
    let endY = y2;
    let marshal;

    ldState.tr.enabledAnchors(['top-left', 'top-center', 'top-right', 'middle-right', 'middle-left', 'bottom-left', 'bottom-center', 'bottom-right']);

    // Always define from left to right, top to bottom
    if (startX > endX) {
      [startX, endX] = [endX, startX];
    }
    if (startY > endY) {
      [startY, endY] = [endY, startY];
    }

    if (ldState.currentDrawType === 'Line' && startY === endY) {
      if (endX - startX < ldState.MIN_DIMENSION) {
        endX = startX + ldState.MIN_DIMENSION;
      }
    } else if (ldState.currentDrawType === 'Line' && startX === endX) {
      if (endY - startY < ldState.MIN_DIMENSION) {
        endY = startY + ldState.MIN_DIMENSION;
      }
    } else {
      if (endX - startX < ldState.MIN_DIMENSION) {
        endX = startX + ldState.MIN_DIMENSION;
      }
      if (endY - startY < ldState.MIN_DIMENSION) {
        endY = startY + ldState.MIN_DIMENSION;
      }
    }

    if (ldState.currentDrawType === 'Ellipse') {
      shape = new LdEllipse(startX, startY, endX - startX, endY - startY);
      recttmp = shape.generate();
    } else if (ldState.currentDrawType === 'TextBox') {
      shape = new LdText(startX, startY, endX - startX, endY - startY);
      recttmp = shape.generate();
    } else if (ldState.currentDrawType === 'VariableBox') {
      shape = new LdVariable(startX, startY, endX - startX, endY - startY);
      recttmp = shape.generate();
    } else if (ldState.currentDrawType === 'Line') {
      shape = new LdLine(startX, startY, endX - startX, endY - startY, endX, endY);
      recttmp = shape.generate();
      if (startY === endY) {
        ldState.tr.enabledAnchors(['middle-left', 'middle-right']);
      } else {
        ldState.tr.enabledAnchors(['top-center', 'bottom-center']);
      }
    } else {
      shape = new LdRect(startX, startY, endX - startX, endY - startY);
      recttmp = shape.generate();
    }
    if (ldState.currentDrawType === 'VariableBox') {
      ldState.layerVar.add(recttmp);
    } else {
      ldState.layer.add(recttmp);
    }
    ldState.tr.nodes([recttmp]);

    ldState.stage.draw();
    ldState.changesMade = true;

    ldState.currentMode = 'select';
    ldState.selectedShape = recttmp;
    ldState.stage.fire('ldSelectOne');

    // set select button to active
    document.querySelectorAll('[data-active]').forEach(elem => elem.dataset.active = 'false');
    document.querySelector('[data-action="select"]').dataset.active = 'true';

    // Automatically select the text for a text box so the user can just start typing
    if (ldState.currentDrawType === 'TextBox') {
      document.querySelector('#ldSave').focus();
      ldState.textButtons.text.select();
    }
    ldState.currentDrawType = undefined;

    marshal = new LdMarshal(recttmp);
    const newNode = marshal.dump();
    UndoEngine.addCommand({
      shapeId: recttmp._id, // eslint-disable-line no-underscore-dangle
      action: 'add',
      current: newNode,
      previous: null,
      executeUndo() {
        const item = getShapeById(this.shapeId);
        // remove from selection if the shape we are about to delete is selected.
        if (ldState.tr.nodes().indexOf(item) >= 0) {
          const hold = ldState.tr.nodes().slice(); // use slice to have new copy of array
          // remove node from array
          hold.splice(hold.indexOf(item), 1);
          ldState.tr.nodes(hold);
        }

        item.destroy();
        ldState.stage.draw();
        console.log('UNDO', this.shapeId, this.action, this.previous);
      },
      executeRedo() {
        marshal = new LdMarshal(newNode);
        const item = marshal.load();
        UndoEngine.replaceId(this.shapeId, item._id); // eslint-disable-line no-underscore-dangle
        ldState.stage.draw();
        console.log('REDO', this.shapeId, this.action, this.current);
      },
    });
  };

  const findAbsolutePos = (obj) => {
    // Source: http://www.quirksmode.org/js/findpos.html
    let currentLeft = 0;
    let currentTop = 0;
    if (obj.offsetParent) {
      do {
        currentLeft += obj.offsetLeft;
        currentTop += obj.offsetTop;
      } while (obj = obj.offsetParent); // eslint-disable-line no-cond-assign, no-param-reassign
      return [currentLeft, currentTop];
    }
    return false;
  };
  const getContainerOffset = () => {
    const canvasOffset = findAbsolutePos(ldCanvas);
    const scrollOffsetLeft = document.querySelector('.designer-container').scrollLeft;
    const scrollOffsetTop = document.querySelector('.designer-container').scrollTop;

    const offsetLeft = parseInt(canvasOffset[0], 10) - parseInt(scrollOffsetLeft, 10);
    const offsetTop = parseInt(canvasOffset[1], 10) - parseInt(scrollOffsetTop, 10);
    return [offsetLeft, offsetTop];
  };
  const getMouseCoordsRelativeToPage = (event) => {
    const evt = event || window.event;
    if (evt.pageX || evt.pageY) {
      return { x: evt.pageX, y: evt.pageY };
    }
    return {
      x: (evt.clientX + document.body.scrollLeft) - document.body.clientLeft,
      y: (evt.clientY + document.body.scrollTop) - document.body.clientTop,
    };
  };
  const getCoords = (event) => {
    const mouseCoords = getMouseCoordsRelativeToPage(event);
    const offset = getContainerOffset(event);
    // const offset = [0, 0];
    return [(mouseCoords.x - offset[0]), (mouseCoords.y - offset[1])];
  };

  let startX = null;
  let startY = null;
  let endX = null;
  let endY = null;

  // Mouse down - record start position
  ldCanvas.addEventListener('mousedown', (event) => {
    // TODO: Look at: https://konvajs.org/docs/sandbox/Relative_Pointer_Position.html
    // - for using Stage to get x/y...
    [startX, startY] = getCoords(event);
    if (ldState.currentMode !== 'select') {
      ldState.outline.x(startX);
      ldState.outline.y(startY);
      ldState.layer.add(ldState.outline);
    }
    // console.log('starting', startX, startY);
  });

  // While the mouse is bring dragged, display an outline of the proposed shape extents
  ldCanvas.addEventListener('mousemove', (event) => {
    // Might want to debounce...
    let tmpX;
    let tmpY;
    if (ldState.currentMode !== 'select') {
      [tmpX, tmpY] = getCoords(event);
      ldState.outline.width(tmpX - startX);
      ldState.outline.height(tmpY - startY);
      ldState.layer.draw();
    }
  });

  // At end of drag, call drawNew to generate the new shape with the start and end coordinates
  ldCanvas.addEventListener('mouseup', (event) => {
    if (ldState.currentMode !== 'select') {
      ldState.outline.remove();

      [endX, endY] = getCoords(event);
      if (ldState.currentDrawType === 'Line') {
        if (Math.abs(endX - startX) > Math.abs(endY - startY)) {
          endY = startY;
        } else {
          endX = startX;
        }
        drawNew(startX, startY, endX, endY);
      } else if (event.ctrlKey) {
        // Make a square
        const len = Math.min((endX - startX), (endY - startY));
        drawNew(startX, startY, startX + len, startY + len);
      } else {
        drawNew(startX, startY, endX, endY);
      }
    }
  });

  // Convert an old label design to a version 1 design
  const convert = (strConfig) => {
    // const config = JSON.parse(strConfig);
    // const config = JSON.parse(strConfig.labelJSON);
    // const config = JSON.parse(strConfig);
    const config = strConfig;
    // console.log(strConfig);
    const shapes = config.shapes;
    const images = JSON.parse(config.imageKeeperJSON);
    // const images = config.imageKeeperJSON;
    let node;
    let points;
    let groupAttrs;
    let textAttrs;
    let dShape;
    let oBox;
    let family;
    let style;
    let varAttrs;
    let rotation;
    let rotX;
    let rotY;

    const jsonOut = {
      width: ldState.stage.width(),
      height: ldState.stage.height(),
      nodes: [],
    };
    // console.log('shapes', shapes.length);

    shapes.forEach((shape) => {
      // Convert IMAGE
      if (shape.attrs.name === 'Image') {
        groupAttrs = JSON.parse(shape.group).attrs;
        oBox = JSON.parse(shape.outerBox).attrs;
        node = {
          x: groupAttrs.x,
          y: groupAttrs.y,
          endX: groupAttrs.x + oBox.width,
          endY: groupAttrs.y + oBox.height,
          name: 'image',
          width: oBox.width,
          height: oBox.height,
        };
        const imgSrc = images.sourceIDArray.filter(ar => ar.imageId === shape.imageID)[0].imageSource;
        node.imageSource = imgSrc;

        jsonOut.nodes.push(node);
      }

      // Convert LINE
      if (shape.attrs.name === 'Line') {
        groupAttrs = JSON.parse(shape.group).attrs;
        dShape = JSON.parse(shape.drawnShape);
        points = dShape.attrs.points;
        if (groupAttrs.rotation === 90) {
          if (points[2] === 0) {
            points[2] = points[3] * -1;
            points[3] = 0;
          } else {
            [points[2], points[3]] = [points[3], points[2]];
          }
        }
        if (groupAttrs.rotation === 180) {
          points[2] *= -1;
          points[3] *= -1;
        }
        if (groupAttrs.rotation === 270) {
          if (points[2] === 0) {
            [points[2], points[3]] = [points[3], points[2]];
          } else {
            points[3] = points[2] * -1;
            points[2] = 0;
          }
        }
        node = {
          x: groupAttrs.x,
          y: groupAttrs.y,
          endX: groupAttrs.x + points[2],
          endY: groupAttrs.y + points[3],
          name: 'line',
          width: points[2] - points[0],
          height: points[3] - points[1],
          strokeWidth: Number(dShape.attrs.strokeWidth || 2),
        };
        jsonOut.nodes.push(node);
      }

      // Convert ELLIPSE
      if (shape.attrs.name === 'Ellipse') {
        groupAttrs = JSON.parse(shape.group).attrs;
        dShape = JSON.parse(shape.drawnShape).attrs;
        oBox = JSON.parse(shape.outerBox).attrs;
        node = {
          x: groupAttrs.x + (dShape.radiusX / 2),
          y: groupAttrs.y + (dShape.radiusY / 2),
          name: 'ellipse',
          width: dShape.radiusX, // oBox.width / 2,
          height: dShape.radiusY, // oBox.height / 2,
          strokeWidth: Number(dShape.strokeWidth || 2),
        };
        jsonOut.nodes.push(node);
      }

      // Convert RECT
      if (shape.attrs.name === 'Rect') {
        groupAttrs = JSON.parse(shape.group).attrs;
        dShape = JSON.parse(shape.drawnShape).attrs;
        node = {
          x: groupAttrs.x,
          y: groupAttrs.y,
          name: 'rect',
          width: dShape.width,
          height: dShape.height,
          strokeWidth: Number(dShape.strokeWidth || 2),
        };
        // ROTATE
        if (groupAttrs.rotation === 90) {
          node.x = groupAttrs.x - dShape.height;
          node.y = groupAttrs.y;
          node.width = dShape.height;
          node.height = dShape.width;
        }
        if (groupAttrs.rotation === 180) {
          node.x -= node.width;
          node.y -= node.height;
        }
        if (groupAttrs.rotation === 270) {
          node.width = dShape.height;
          node.height = dShape.width;
          node.y -= node.height;
        }
        jsonOut.nodes.push(node);
      }

      // Convert VARIABLE
      if (shape.attrs.name === 'VariableBox') {
        // console.log('VariableBox', shape.attrs);
        dShape = shape.attrs;
        groupAttrs = JSON.parse(shape.group).attrs;
        textAttrs = JSON.parse(shape.textBox).attrs;
        family = dShape.fontFamily;
        if (dShape.bold) {
          if (dShape.italic) {
            style = 'bold italic';
          } else {
            style = 'bold';
          }
        } else if (dShape.italic) {
          style = 'italic';
        } else {
          style = 'normal';
        }

        varAttrs = {
          whiteOnBlack: shape.attrs.whiteOnBlack === 'true' || false,
          barcode: shape.attrs.isBarcode === 'true',
          barcodeText: shape.attrs.showBarcodeText === 'true',
          barcodeTop: shape.attrs.barcodeTop,
          barcodeWidthFactor: Number(shape.attrs.barcodeWidthFactor),
          barcodeSymbology: shape.attrs.barcodeSymbology,
          staticValue: shape.attrs.staticValue || null,
        };

        node = {
          x: groupAttrs.x,
          y: groupAttrs.y,
          name: 'variableBox',
          width: dShape.width,
          height: dShape.height,

          fontSize: Number(dShape.fontSizePx),
          fontFamily: family,
          text: textAttrs.text,
          fontStyle: style,
          textDecoration: textAttrs.textDecoration || '',
          align: dShape.alignment || 'left',
          rotation: groupAttrs.rotation || 0, // TODO: correct the x & y & width  + height (might need to "correct the shape" first to horiz.
          varType: shape.attrs.variableType,
          varAttrs,
        };

        jsonOut.nodes.push(node);
      }

      // Convert TEXT
      if (shape.attrs.name === 'TextBox') {
        // console.log('TextBox', shape.textBox);
        groupAttrs = JSON.parse(shape.group).attrs;
        dShape = JSON.parse(shape.textBox).attrs;
        // console.log('text', dShape, 'groupAttrs', groupAttrs);
        family = 'Arial';
        style = 'normal';
        switch (dShape.fontFamily) {
          case 'ArialB':
            style = 'bold';
            break;
          case 'ArialI':
            style = 'italic';
            break;
          case 'ArialBI':
            style = 'bold italic';
            break;
          case 'Cour':
            family = 'Courier New';
            break;
          case 'CourB':
            family = 'Courier New';
            style = 'bold';
            break;
          case 'CourI':
            family = 'Courier New';
            style = 'italic';
            break;
          case 'CourBI':
            family = 'Courier New';
            style = 'bold italic';
            break;
          case 'TNR':
            family = 'Times New Roman';
            break;
          case 'TNRB':
            family = 'Times New Roman';
            style = 'bold';
            break;
          case 'TNRI':
            family = 'Times New Roman';
            style = 'italic';
            break;
          case 'TNRBI':
            family = 'Times New Roman';
            style = 'bold italic';
            break;
          case 'LatoL':
            family = 'Lato Light';
            break;
          case 'LatoLB':
            family = 'Lato Light';
            style = 'bold';
            break;
          case 'LatoLI':
            family = 'Lato Light';
            style = 'italic';
            break;
          case 'LatoLBI':
            family = 'Lato Light';
            style = 'bold italic';
            break;
          default:
            family = 'Arial';
            style = 'normal';
        }
        rotation = groupAttrs.rotation || 0;
        if (rotation === 0) {
          rotX = groupAttrs.x + (dShape.padding || 0);
          rotY = groupAttrs.y + (dShape.padding || 0);
        } else if (rotation === 90) {
          rotX = groupAttrs.x - (dShape.padding || 0);
          rotY = groupAttrs.y + (dShape.padding || 0);
        } else if (rotation === 180) {
          rotX = groupAttrs.x - (dShape.padding || 0);
          rotY = groupAttrs.y - (dShape.padding || 0);
        } else {
          rotX = groupAttrs.x + (dShape.padding || 0);
          rotY = groupAttrs.y - (dShape.padding || 0);
        }

        node = {
          x: rotX,
          y: rotY,
          name: 'textBox',
          width: dShape.width - (dShape.padding || 0),
          height: dShape.height - (dShape.padding || 0),

          fontSize: Number(dShape.fontSize),
          fontFamily: family,
          text: dShape.text,
          fontStyle: style,
          textDecoration: dShape.textDecoration || '',
          align: dShape.align || 'left',
          rotation,
        };
        jsonOut.nodes.push(node);
      }
    });

    // console.log('import', jsonOut);
    return jsonOut;
  };

  // Load a label design
  const load = (strConfig) => {
    let marshal;

    let config = typeof strConfig === 'string' ? JSON.parse(strConfig) : strConfig;
    if (!config.version) {
      // Show an upgrade message to the user
      document.getElementById('upgradeNote').hidden = false;
      config = convert(strConfig);
    }

    config.nodes.forEach((node) => {
      marshal = new LdMarshal(node);
      marshal.load();
    });

    ldState.stage.draw();
  };

  const hasUnsetVariables = () => ldState.layerVar.getChildren().some(item => item.attrs.varType === 'unset');

  const changesMade = () => ldState.changesMade;

  // Variable numbers can develop gaps when any are deleted, and static barcodes must not be counted
  // This function renumbers the variables, keeping the existing sequence as much as possible
  const renumberVariables = () => {
    let pos;
    let varNum;
    const items = ldState.layerVar.getChildren()
      .filter(item => item.attrs.varType !== 'Static Barcode')
      .map(item => item.attrs.varNum)
      .sort((a, b) => a - b);

    if (items.length === 0) { return; }

    const seqs = Array(items.length).fill().map((_, idx) => 1 + idx);
    if (items.every((a, i) => a === seqs[i])) { return; }

    ldState.layerVar.getChildren().filter(item => item.attrs.varType !== 'Static Barcode').forEach((item) => {
      varNum = item.attrs.varNum;
      pos = items.indexOf(varNum);
      if (seqs[pos] !== varNum) {
        item.attrs.varNum = seqs[pos];
      }
    });
  };

  // Dump the canvas' shapes to a JSON object.
  const dump = () => {
    let marshal;

    renumberVariables();

    const jsonOut = {
      version: 1,
      width: ldState.stage.width(),
      height: ldState.stage.height(),
      nodes: [],
    };

    ldState.layerVar.getChildren().forEach((item) => {
      if (item.name() === 'variableBox') {
        marshal = new LdMarshal(item);
        jsonOut.nodes.push(marshal.dump());
      }
    });

    ldState.layer.getChildren().forEach((item) => {
      if (item.getClassName() === 'Transformer') {
        return;
      }
      marshal = new LdMarshal(item);
      jsonOut.nodes.push(marshal.dump());
    });

    return jsonOut;
  };

  // Save the label design to the backend
  const saveLabel = () => {
    const form = new FormData();
    form.append('labelName', ldState.labelConfig.labelName);
    form.append('labelDimension', ldState.labelConfig.labelDimension);
    form.append('pixelPerMM', ldState.labelConfig.pxPerMm);
    form.append('label', JSON.stringify(dump()));
    form.append('imageString', getBackgroundImage());
    form.append('labelWidth', ldState.labelConfig.width);
    form.append('labelHeight', ldState.labelConfig.height);
    form.append('_csrf', document.querySelector('meta[name="_csrf"]').content);

    fetch(ldState.savePath, {
      method: 'post',
      credentials: 'same-origin',
      headers: new Headers({
        'X-Custom-Request-Type': 'Fetch',
      }),
      body: form,
    })
      .then(response => response.json())
      .then((data) => {
        if (data.redirect) {
          ldState.changesMade = false;
          window.location = data.redirect;
        } else if (data.flash) {
          if (data.flash.notice) {
            Jackbox.success(data.flash.notice);
          }
          if (data.flash.error) {
            if (data.exception) {
              Jackbox.error(data.flash.error, { time: 20 });
              if (data.backtrace) {
                console.groupCollapsed('EXCEPTION:', data.exception, data.flash.error); // eslint-disable-line no-console
                console.info('==Backend Backtrace=='); // eslint-disable-line no-console
                console.info(data.backtrace.join('\n')); // eslint-disable-line no-console
                console.groupEnd(); // eslint-disable-line no-console
              }
            } else {
              Jackbox.error(data.flash.error);
            }
          }
        }
      })
      .catch((data) => {
        if (data.response && data.response.status === 500) {
          data.response.json().then((body) => {
            if (body.flash.error) {
              if (body.exception) {
                if (body.backtrace) {
                  console.groupCollapsed('EXCEPTION:', body.exception, body.flash.error); // eslint-disable-line no-console
                  console.info('==Backend Backtrace=='); // eslint-disable-line no-console
                  console.info(body.backtrace.join('\n')); // eslint-disable-line no-console
                  console.groupEnd(); // eslint-disable-line no-console
                }
              } else {
                Jackbox.error(body.flash.error);
              }
            } else {
              console.debug(body); // eslint-disable-line no-console
            }
          });
        }
        Jackbox.error(`An error occurred ${data}`, { time: 20 });
      });
  };

  // Listen for click on the save button
  document.querySelector('#ldSave').addEventListener('click', () => {
    saveLabel();
  });

  // Write debug information to the page
  const debug = () => {
    let no;
    let fno;
    let nm;
    let txtObj;
    const nodes = ldState.layer.getChildren().map((item) => {
      nm = item.name();
      return `<li>${item._id} - ${nm || item.getClassName()}</li>`; // eslint-disable-line no-underscore-dangle
    });
    ldState.layerVar.getChildren().forEach((item) => {
      no = item.getAttr('varNum');
      fno = no ? ` (F${no})` : '';
      nm = item.name();
      [txtObj] = item.getChildren(node => node.getClassName() === 'Text');
      nodes.push(`<li>${item._id} - ${nm || item.getClassName()}${fno} : ${txtObj.text()}</li>`); // eslint-disable-line no-underscore-dangle
    });
    const out = `<ul>${nodes.join('')}</ul>`;
    // console.log(out);

    debugSpace.innerHTML = out;
  };

  const getTransformer = () => ldState.tr;

  return {
    init,
    getSelectedShape,
    getSelectedMultiple,
    getCurrentMode,
    getCurrentDrawType,
    getTransformer,
    align,
    debug,
    dump,
    load,
    convert,
    getBackgroundImage,
    renumberVariables,
    hasUnsetVariables,
    changesMade,
  };
}());
