/* eslint-disable no-return-assign */
const LabelDesigner = (function LabelDesigner() { // eslint-disable-line max-classes-per-file
  const ldState = { changesMade: false };
  const debugSpace = document.getElementById('debugSpace');
  const menuNode = document.getElementById('varMenu');

  class LdShape {
    constructor(x, y, width, height) {
      this.x = x;
      this.y = y;
      this.width = width;
      this.height = height;
    }
  }

  class LdImage extends LdShape {
    generate(opts = {}) {
      const img = new Image();
      img.src = opts.imageSource; // might need to do onLoad...

      this.shape = new Konva.Image({
        x: this.x,
        y: this.y,
        image: img,
        name: 'image',
        draggable: true,
        imageSource: opts.imageSource,
      });
      if (this.width) {
        this.shape.width(this.width);
      } else {
        this.shape.width(this.shape.attrs.image.width);
      }
      if (this.height) {
        this.shape.height(this.height);
      } else {
        this.shape.height(this.shape.attrs.image.height);
      }
      return this.shape;
    }
  }

  class LdRect extends LdShape {
    generate(opts = {}) {
      this.shape = new Konva.Rect({
        x: this.x,
        y: this.y,
        width: this.width,
        height: this.height,
        stroke: 'black',
        strokeWidth: opts.strokeWidth || 2,
        strokeScaleEnabled: false,
        draggable: true,
        name: 'rect',
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
      this.shape = new Konva.Line({
        points: [this.x, this.y, this.endX, this.endY],
        stroke: 'black',
        strokeWidth: opts.strokeWidth || 2,
        strokeScaleEnabled: false,
        draggable: true,
        hitStrokeWidth: 10,
        name: 'line',
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
        barcodeMargin: optAttrs.barcodeMargin || 5,
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
        x: 0,
        y: 0,
        width: this.width,
        height: this.height,
        fontSize: opts.fontSize || 22,
        fontFamily: opts.fontFamily || 'Arial',
        text: opts.text || 'Unset Variable',
        fill: txtFill,
        name: 'text',
        fontStyle: opts.fontStyle || 'normal',
        textDecoration: opts.textDecoration || '',
        align: opts.align || 'left',
        rotation,
      });
      const rectPart = new Konva.Rect({
        x: 0,
        y: 0,
        width: this.width,
        height: this.height,
        stroke: opts.stroke || rectFill,
        strokeWidth: 2,
        strokeScaleEnabled: false,
        name: 'rect',
        rotation,
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
      this.shape = new Konva.Text({
        x: this.x,
        y: this.y,
        width: this.width,
        height: this.height,
        fontSize: opts.fontSize || 22,
        fontFamily: opts.fontFamily || 'Arial',
        text: opts.text || 'Text',
        fill: 'black',
        draggable: true,
        name: 'textBox',
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
      });
      return this.shape;
    }
  }

  class LdEllipse extends LdShape {
    generate(opts = {}) {
      this.shape = new Konva.Ellipse({
        x: this.x + (this.width / 2),
        y: this.y + (this.height / 2),
        radiusX: this.width,
        radiusY: this.height,
        stroke: 'black',
        strokeWidth: opts.strokeWidth || 2,
        strokeScaleEnabled: false,
        draggable: true,
        name: 'ellipse',
      });
      return this.shape;
    }
  }

  class LdMarshal {
    constructor(elem) {
      this.elem = elem;
    }

    dump() {
      let node;
      let txtObj;

      node = {
        x: this.elem.x(),
        y: this.elem.y(),
        name: this.elem.name(),
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
        node.width = this.elem.radiusX();
        node.height = this.elem.radiusY();
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
        if (this.elem.rotation() === 90 || this.elem.rotation() === 270) {
          node.width = this.elem.height();
          node.height = this.elem.width();
        }
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

    load(offset = 0) {
      let shape;
      let item;

      if (this.elem.name === 'image') {
        shape = new LdImage(this.elem.x + offset, this.elem.y + offset, this.elem.width, this.elem.height);
        item = shape.generate(this.elem);
        ldState.layer.add(item);
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
  const resolveTextObject = (item) => {
    const txtObj = item || ldState.selectedShape;
    if (txtObj.hasChildren()) {
      const tmp = txtObj.getChildren(node => node.getClassName() === 'Text')[0];
      // console.log('txt-var', tmp);
      return tmp;
    }
    return txtObj;
  };

  const LINE_TYPES = {
    line: true,
    rect: true,
    ellipse: true,
  };

  const lineTypeSelected = () => {
    // console.log('type', ldState.selectedShape.name(), LINE_TYPES[ldState.selectedShape.name()]);
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

  const init = (labelConfig) => {
    // pass in width & height, label sizes(?), px/mm, label var options(?), design json
    // const labelConfig = <%= @label_config %>;
    // const labelSizes = <%= @label_sizes %>; --  change to w + h?
    // const fontSizes = <%= @font_sizes_json %>; == popint to px (could be fixed in JS def - OR does this depend on px/mm?)
    // const pxPerMm = <%= @px_per_mm %>;
    // const fontDefaultPx = <%= @default_font_px %>; -- can hard-code to 22
    // const fontDefaultPt = <%= @default_font_pt %>; -- can hard-code to 8 (or translate from font sizes table)
    ldState.MIN_DIMENSION = 20;
    ldState.selectedShape = undefined;
    ldState.selectedMultiple = [];
    ldState.currentMode = 'select';
    ldState.currentDrawType = undefined;
    ldState.varNum = 0;
    ldState.clipboard = { shapes: [] };
    ldState.copyOffset = 5;

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
      if (ldState.selectedMultiple.length > 0) {
        ldState.selectedMultiple.forEach(item => item.strokeWidth(Number(ldState.lineWidth.value)));
      } else {
        ldState.selectedShape.strokeWidth(Number(ldState.lineWidth.value));
      }
      ldState.stage.draw();
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
      if (files.length > 0) {
        const file = files[0];
        if (file) {
          const reader = new FileReader();
          reader.readAsDataURL(file);
          reader.onload = function readOnload(event) {
            const shape = new LdImage(0, 0);
            const recttmp = shape.generate({ imageSource: event.target.result });
            ldState.layer.add(recttmp);
            ldState.tr.nodes([recttmp]);

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
          };
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
      barcodeMargin: document.querySelector('#barcode_margin'),
    };

    // Listen for change of text input and update Text of Variable contents
    ldState.textButtons.text.addEventListener('input', () => {
      const txtObj = resolveTextObject();
      txtObj.text(ldState.textButtons.text.value);
      ldState.stage.draw();
    });

    // Listen for change of font size
    ldState.textButtons.fontSize.addEventListener('change', () => {
      let txtObj;
      if (ldState.selectedMultiple.length > 0) {
        ldState.selectedMultiple.forEach((item) => {
          txtObj = resolveTextObject(item);
          txtObj.fontSize(Number(ldState.textButtons.fontSize.value));
        });
      } else {
        txtObj = resolveTextObject();
        txtObj.fontSize(Number(ldState.textButtons.fontSize.value));
      }
      ldState.stage.draw();
    });

    // Listen for change of font family
    ldState.textButtons.fontFamily.addEventListener('change', () => {
      let txtObj;
      if (ldState.selectedMultiple.length > 0) {
        ldState.selectedMultiple.forEach((item) => {
          txtObj = resolveTextObject(item);
          txtObj.fontFamily(ldState.textButtons.fontFamily.value);
        });
      } else {
        txtObj = resolveTextObject();
        txtObj.fontFamily(ldState.textButtons.fontFamily.value);
      }
      ldState.stage.draw();
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
    ldState.stage.on('dragstart', () => {
      if (ldState.currentMode !== 'select') {
        ldState.stage.stopDrag();
      }
    });

    // Single shape selected
    ldState.stage.on('ldSelectOne', () => {
      ldState.selectedMultiple = [];
      ldState.tr.enabledAnchors(['top-left', 'top-center', 'top-right', 'middle-right', 'middle-left',
        'bottom-left', 'bottom-center', 'bottom-right']);
      setSelectedButtons(true, textTypeSelected());
      setCopyButtons(true);
      setAlignButtons(false);
      if (lineTypeSelected()) {
        setLineButtons(true);
        if (ldState.selectedShape.name() === 'line') {
          ldState.tr.enabledAnchors(['middle-right', 'middle-left']);
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
    ldState.layer.add(ldState.tr);
    ldState.stage.add(ldState.layer);
    ldState.stage.add(ldState.layerVar);

    // Listen for select/unselect in the canvas stage
    ldState.stage.on('click tap', (e) => {
      // if click on empty area - remove all selections
      if (e.target === ldState.stage) {
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
        ldState.tr.nodes([target]);
        ldState.selectedShape = target;
        ldState.stage.fire('ldSelectOne');
      } else if (metaPressed && isSelected) {
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
          ldState.stage.fire('ldSelectMultiple');
        }
      } else if (metaPressed && !isSelected) {
        // add the node into selection
        const nodes = ldState.tr.nodes().concat([target]);
        ldState.tr.nodes(nodes);
        ldState.selectedMultiple = nodes;
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
        return;
      }
      if (ldState.selectedMultiple.length > 0) {
        return;
      }
      const parentGroup = e.target.findAncestor('Group');
      if (!parentGroup || parentGroup.name() !== 'variableBox') {
        return;
      }

      // Make selection
      ldState.tr.nodes([parentGroup]);
      ldState.selectedShape = parentGroup;
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
    const txtObj = ldState.selectedShape.getChildren(node => node.getClassName() === 'Text')[0];
    const rectObj = ldState.selectedShape.getChildren(node => node.getClassName() === 'Rect')[0];
    const varAttrs = {
      whiteOnBlack: ldState.variableUI.whiteOnBlack.checked,
      barcode: ldState.variableUI.barcodeBool.checked,
      barcodeText: ldState.variableUI.barcodeText.checked,
      barcodeTop: ldState.variableUI.barcodeTop.value,
      barcodeWidthFactor: ldState.variableUI.barcodeWidthFactor.value,
      barcodeMargin: ldState.variableUI.barcodeMargin.value,
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
        // UndoRedoModule.registerUndoEvent();

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

  // On resize of a shape, ensure the shape does not end up too small to work with
  const adjustWidth = (elem, width) => {
    let points;
    // VAR...
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
  };

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

    ldState.clipboard.shapes.forEach((shape) => {
      marshal = new LdMarshal(shape);
      newSelection.push(marshal.load(ldState.copyOffset));
      ldState.copyOffset += 5;
    });
    if (newSelection.length === 1) {
      ldState.currentMode = 'select';
      ldState.tr.nodes(newSelection);
      ldState.selectedShape = newSelection[0];
    } else {
      ldState.tr.nodes(newSelection);
      ldState.selectedMultiple = newSelection;
    }
  };

  // De-select any shapes and return a png copy of all shapes except those on the variable layer
  const getBackgroundImage = () => {
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
    ldState.variableUI.barcodeMargin.value = curr.barcodeMargin;
    ldState.variableUI.barcodeSymbology.value = curr.barcodeSymbology;
    ldState.variableUI.staticInputValue.value = curr.staticValue ? curr.staticValue : '';

    // Set the UI barcode show/hide state
    varChange(varType);
    toggleBarcodeOptions(curr.barcode);
  };

  // --- START OF CONTEXT MENU
  document.getElementById('set-variable').addEventListener('click', () => {
    showVariableDialog();
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

    document.querySelector('.btn-download-image').addEventListener('click', (event) => {
      const href = getBackgroundImage();
      document.querySelector('#btn-download-image').href = href;
    });

    document.querySelector('#set-variable-opt').addEventListener('click', (event) => {
      event.preventDefault();
      showVariableDialog();
    });

    document.addEventListener('keydown', (event) => {
      let move;
      let width;
      let height;
      // let points;

      if (event.target.id === 'textinput') {
        return null;
      }
      // if dialog showing, quit
      if (event.target.closest('.dialog-content')) {
        return null;
      }

      if (!ldState.selectedShape && !ldState.selectedMultiple.length > 0) {
        return null;
      }

      if (event.key === 'Delete' && ldState.selectedShape) {
        ldState.selectedShape.destroy();
        ldState.stage.fire('ldSelectNone');
        // console.log('deleteme', event);
      }

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

      if (move) {
        if (ldState.selectedMultiple.length > 0) {
          ldState.selectedMultiple.forEach((elem) => {
            elem.move(move);
          });
        } else {
          ldState.selectedShape.move(move);
        }
      }

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
      if (move || width || height) {
        ldState.stage.draw();
        event.stopPropagation();
        event.preventDefault();
      }
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

      if (btn) {
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
        }
        if (btn.dataset.action === 'remove' && ldState.selectedShape) {
          ldState.selectedShape.destroy();
          ldState.stage.fire('ldSelectNone');
        }
        if (btn.dataset.action === 'copy' && (ldState.selectedShape || ldState.selectedMultiple.length > 0)) {
          copyToClipboard();
        }
        if (btn.dataset.action === 'paste') {
          pasteFromClipboard();
        }
        if (btn.dataset.image) {
          ldState.imgUpDialog.show();
        }
      }

      btn = event.target.closest('button[data-textstyle]');
      if (btn) {
        enable = btn.dataset.selected === 'false';
        btn.dataset.selected = enable;
        if (ldState.selectedMultiple.length > 0) {
          ldState.selectedMultiple.forEach((item) => {
            applyTextStyle(enable, btn.dataset.textstyle, item);
          });
        } else {
          applyTextStyle(enable, btn.dataset.textstyle);
        }
        ldState.stage.draw();
      }

      btn = event.target.closest('button[data-alignment]');
      if (btn) {
        document.querySelectorAll('button[data-alignment]').forEach(elem => elem.dataset.selected = 'false');
        btn.dataset.selected = 'true';
        if (ldState.selectedMultiple.length > 0) {
          ldState.selectedMultiple.forEach((item) => {
            applyTextAlignment(btn.dataset.alignment, item);
          });
        } else {
          applyTextAlignment(btn.dataset.alignment);
        }
        ldState.stage.draw();
      }
    });
  });

  const getSelectedShape = () => ldState.selectedShape;

  const getSelectedMultiple = () => ldState.selectedMultiple;

  // Align shapes along top or left edges
  const align = (edge) => {
    let startPoint;

    if (ldState.selectedMultiple.length === 0) {
      return 'Multiple shapes have not been selected';
    }

    if (edge === 'left') {
      if (ldState.selectedMultiple[0].name() === 'line') {
        startPoint = ldState.selectedMultiple[0].points()[0];
      } else if (ldState.selectedMultiple[0].name() === 'ellipse') {
        startPoint = ldState.selectedMultiple[0].x() - ldState.selectedMultiple[0].radiusX();
      } else {
        startPoint = ldState.selectedMultiple[0].x();
      }
      for (let i = 1; i < ldState.selectedMultiple.length; i += 1) {
        if (ldState.selectedMultiple[i].name() === 'line') {
          const points = ldState.selectedMultiple[i].points();
          const shift = points[0] - startPoint;
          points[0] = startPoint;
          points[2] -= shift;
          ldState.selectedMultiple[i].points(points);
        } else if (ldState.selectedMultiple[i].name() === 'ellipse') {
          ldState.selectedMultiple[i].move({ x: (startPoint - (ldState.selectedMultiple[i].x() - ldState.selectedMultiple[i].radiusX())), y: 0 });
        } else {
          ldState.selectedMultiple[i].move({ x: (startPoint - ldState.selectedMultiple[i].x()), y: 0 });
        }
      }
      ldState.stage.draw();
    }

    if (edge === 'top') {
      if (ldState.selectedMultiple[0].name() === 'line') {
        startPoint = ldState.selectedMultiple[0].points()[1];
      } else if (ldState.selectedMultiple[0].name() === 'ellipse') {
        startPoint = ldState.selectedMultiple[0].y() - ldState.selectedMultiple[0].radiusY();
      } else {
        startPoint = ldState.selectedMultiple[0].y();
      }
      for (let i = 1; i < ldState.selectedMultiple.length; i += 1) {
        if (ldState.selectedMultiple[i].name() === 'line') {
          const points = ldState.selectedMultiple[i].points();
          const shift = points[1] - startPoint;
          points[1] = startPoint;
          points[3] -= shift;
          ldState.selectedMultiple[i].points(points);
        } else if (ldState.selectedMultiple[i].name() === 'ellipse') {
          ldState.selectedMultiple[i].move({ x: 0, y: (startPoint - (ldState.selectedMultiple[i].y() - ldState.selectedMultiple[i].radiusY())) });
        } else {
          ldState.selectedMultiple[i].move({ x: 0, y: (startPoint - ldState.selectedMultiple[i].y()) });
        }
      }
      ldState.stage.draw();
    }
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
    ldState.tr.enabledAnchors(['top-left', 'top-center', 'top-right', 'middle-right', 'middle-left', 'bottom-left', 'bottom-center', 'bottom-right']);

    // Always define from left to right, top to bottom
    if (startX > endX) {
      [startX, endX] = [endX, startX];
    }
    if (startY > endY) {
      [startY, endY] = [endY, startY];
    }

    if (startX === endX) {
      if (endY - startY < ldState.MIN_DIMENSION) {
        endY = startY + ldState.MIN_DIMENSION;
      }
    } else if (startY === endY) {
      if (endX - startX < ldState.MIN_DIMENSION) {
        endX = startX + ldState.MIN_DIMENSION;
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
          barcodeMargin: Number(shape.attrs.barcodeMargin),
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
