/* eslint-disable no-return-assign */
const LabelDesigner = (function LabelDesigner() { // eslint-disable-line max-classes-per-file
  const ldThis = { changesMade: false };
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
    // XML requirements from var:
    // --------------------------
    // <id>57</id>
    // <variable_field_count>F3</variable_field_count>
    // <variable_type>Commodity Description</variable_type>
    //
    // S: <rotation_angle>0</rotation_angle>
    // S: <startx>215</startx>
    // S: <starty>159</starty>
    // S: <width>257</width>
    // S: <height>63</height>
    // S: <fontsize_px>38</fontsize_px>
    // <fontsize_pt>14</fontsize_pt>  -- derive from lookup table...
    // S: <align>left</align>
    // S: <fontfamily>Arial</fontfamily>
    // S: <bold>false</bold>
    // S: <italic>false</italic>
    // S: <underline>false</underline>
    //
    // <barcode>false</barcode>
    // <barcodetext>false</barcodetext>
    // <barcodetop>true</barcodetop>
    // <barcodewidthfactor>1.5</barcodewidthfactor>
    // <barcode_margin_px>5</barcode_margin_px>
    // <barcode_symbology>CODE_128</barcode_symbology>

    // NOTE: need to resize with transformer without altering text size
    generate(opts = {}) {
      const rotation = opts.rotation || 0;
      if (rotation === 360) {
        rotation = 0;
      }
      const horiz = (rotation === 0) || (rotation === 180)
      const optAttrs = opts.varAttrs || {};
      const varAttrs = {
        // fontSizePt: optAttrs.fontSizePt || 8, // should this be looked-up? Only written on dump() ?
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
        ldThis.varNum = Math.max(ldThis.varNum, vn);
      } else {
        ldThis.varNum += 1;
        vn = ldThis.varNum;
      }

      this.shape = new Konva.Group({
        x: this.x,
        y: this.y,
        // width: this.width,
        // height: this.height,
        width: horiz ? this.width : this.height,
        height: horiz ? this.height : this.width,
        offset: 0,
        draggable: true,
        varNum: vn,
        varType: opts.varType || 'unset',
        varAttrs,
        rotation: rotation,
      });

      const txtPart = new Konva.Text({
        x: 0,
        y: 0,
        width: horiz ? this.width : this.height,
        height: horiz ? this.height : this.width,
        fontSize: opts.fontSize || 22,
        fontFamily: opts.fontFamily || 'Arial',
        text: opts.text || 'Unset Variable',
        fill: txtFill,
        name: 'text',
        fontStyle: opts.fontStyle || 'normal',
        textDecoration: opts.textDecoration || '',
        align: opts.align || 'left',
      });
      const rectPart = new Konva.Rect({
        x: 0,
        y: 0,
        width: horiz ? this.width : this.height,
        height: horiz ? this.height : this.width,
        stroke: opts.stroke || rectFill,
        strokeWidth: 2,
        strokeScaleEnabled: false,
        name: 'rect',
      });
      txtPart.on('transform', () => {
        txtPart.setAttrs({
          width: txtPart.width() * txtPart.scaleX(),
          height: txtPart.height() * txtPart.scaleY(),
          scaleX: 1,
          scaleY: 1,
        });
      });

      // Ensure the text in the variable does not stretch with transforming:
      this.shape.on('transform', () => {
        const txtElem = this.shape.getChildren((node) => node.getClassName() === 'Text')[0];
        const rectElem = this.shape.getChildren(node => node.getClassName() === 'Rect')[0];

        txtElem.setAttrs({
          width: this.shape.width() * this.shape.scaleX(),
          height: this.shape.height() * this.shape.scaleY(),
        });

        rectElem.setAttrs({
          width: Math.max(rectElem.width() * this.shape.scaleX(), ldThis.MIN_DIMENSION),
          height: Math.max(rectElem.height() * this.shape.scaleY(), ldThis.MIN_DIMENSION),
        });

        this.shape.setAttrs({
          width: Math.max(this.shape.width() * this.shape.scaleX(), ldThis.MIN_DIMENSION),
          height: Math.max(this.shape.height() * this.shape.scaleY(), ldThis.MIN_DIMENSION),
        });
        ldThis.layerVar.batchDraw();
      });

      this.shape.on('dblclick', () => {
        ldThis.textButtons.text.focus();
        ldThis.selectedShape = this.shape;
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
        ldThis.textButtons.text.focus();
        ldThis.selectedShape = this.shape;
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
        ldThis.layer.add(item);
      }
      if (this.elem.name === 'rect') {
        shape = new LdRect(this.elem.x + offset, this.elem.y + offset, this.elem.width, this.elem.height);
        item = shape.generate(this.elem);
        ldThis.layer.add(item);
      }
      if (this.elem.name === 'ellipse') {
        shape = new LdEllipse(this.elem.x + offset, this.elem.y + offset, this.elem.width, this.elem.height); // check this seems to increase scale...
        item = shape.generate(this.elem);
        ldThis.layer.add(item);
      }
      if (this.elem.name === 'line') {
        // console.log(this.elem);
        shape = new LdLine(this.elem.x + offset, this.elem.y + offset,
          this.elem.width, this.elem.height,
          this.elem.endX + offset, this.elem.endY + offset);
        item = shape.generate(this.elem);
        ldThis.layer.add(item);
      }
      if (this.elem.name === 'textBox') {
        shape = new LdText(this.elem.x + offset, this.elem.y + offset, this.elem.width, this.elem.height);
        item = shape.generate(this.elem);
        ldThis.layer.add(item);
      }
      if (this.elem.name === 'variableBox') {
        shape = new LdVariable(this.elem.x + offset, this.elem.y + offset, this.elem.width, this.elem.height);
        item = shape.generate(this.elem);
        ldThis.layerVar.add(item);
        if (offset !== 0) {
          ldThis.layerVar.draw();
        }
      } else if (offset !== 0) {
        ldThis.layer.draw();
      }

      return item;
    }
  }
  // --- END OF SHAPES

  // Return the selected text object or the text object within the selected group.
  const resolveTextObject = (item) => {
    const txtObj = item || ldThis.selectedShape;
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
    // console.log('type', ldThis.selectedShape.name(), LINE_TYPES[ldThis.selectedShape.name()]);
    if (LINE_TYPES[ldThis.selectedShape.name()]) return true;

    return false;
  };

  const TEXT_TYPES = {
    textBox: true,
    variableBox: true,
  };

  const textTypeSelected = () => {
    // console.log('type', ldThis.selectedShape.name(), TEXT_TYPES[ldThis.selectedShape.name()]);
    if (TEXT_TYPES[ldThis.selectedShape.name()]) return true;

    return false;
  };

  const setLineButtons = (enable) => {
    // console.log('lineW', ldThis.lineWidth);
    if (enable) {
      ldThis.lineWidth.disabled = false;
      ldThis.lineWidthImg.disabled = false;
      ldThis.lineWidth.value = ldThis.selectedShape.strokeWidth();
    } else {
      ldThis.lineWidth.disabled = true;
      ldThis.lineWidthImg.disabled = true;
      ldThis.lineWidth.value = 2;
    }
  };

  const applyTextState = () => {
    if (ldThis.selectedShape && (ldThis.selectedShape.name() === 'variableBox' || ldThis.selectedShape.name() === 'textBox')) {
      const txtObj = resolveTextObject();
      ldThis.textButtons.bold.dataset.selected = txtObj.fontStyle().split(' ').includes('bold');
      ldThis.textButtons.italic.dataset.selected = txtObj.fontStyle().split(' ').includes('italic');
      ldThis.textButtons.underline.dataset.selected = txtObj.textDecoration() === 'underline';
      ldThis.textButtons.lJust.dataset.selected = txtObj.align() === 'left';
      ldThis.textButtons.cJust.dataset.selected = txtObj.align() === 'center';
      ldThis.textButtons.rJust.dataset.selected = txtObj.align() === 'right';
      ldThis.textButtons.text.value = txtObj.text();
      ldThis.textButtons.fontSize.value = txtObj.fontSize();
      ldThis.textButtons.fontFamily.value = txtObj.fontFamily();
    } else if (ldThis.selectedMultiple.length === 0) {
      document.querySelectorAll('[data-text="button"]').forEach(elem => elem.dataset.selected = false);
      document.querySelector('[data-alignment="left"]').dataset.selected = true;
      ldThis.textButtons.fontSize.value = 22;
      ldThis.textButtons.fontFamily.value = 'Arial';
      ldThis.textButtons.text.value = '';
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
    Array.from(ldThis.textButtons.fontFamily.children).forEach((option) => { option.disabled = false; });
    if (variable) {
      Array.from(ldThis.textButtons.fontFamily.children).forEach((option) => {
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
      setAllowedFontOptions(ldThis.selectedShape.name() === 'variableBox');
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
  }

  const setCopyButtons = (enable) => {
    document.querySelector('[data-action="copy"]').disabled = !enable;
  };

  const setButtonsForMultiple = () => {
    let list;

    setCopyButtons(true);

    // --- Stroke - for shapes
    list = ldThis.selectedMultiple.map((item) => {
      if (['rect', 'line', 'ellipse'].includes(item.name())) {
        return item.strokeWidth();
      }
      return 99;
    });

    if (list[0] !== 99 && list.every(attr => attr === list[0])) {
      ldThis.lineWidth.disabled = false;
      ldThis.lineWidthImg.disabled = false;
      ldThis.lineWidth.value = list[0];
    }

    // --- Text attrs
    list = ldThis.selectedMultiple.map((item) => {
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
      Array.from(ldThis.textButtons.fontFamily.children).forEach((option) => { option.disabled = false; });
      if (list.some(attr => attr === 'var')) {
        Array.from(ldThis.textButtons.fontFamily.children).forEach((option) => {
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
    ldThis.MIN_DIMENSION = 20;
    ldThis.selectedShape = undefined;
    ldThis.selectedMultiple = [];
    ldThis.currentMode = 'select';
    ldThis.currentDrawType = undefined;
    ldThis.varNum = 0;
    ldThis.clipboard = { shapes: [] };
    ldThis.copyOffset = 5;

    ldThis.labelConfig = labelConfig;
    ldThis.savePath = labelConfig.savePath;

    ldThis.lineWidth = document.querySelector('#stroke-width');
    ldThis.lineWidthImg = document.querySelector('#stroke-width-img');
    // Show/hide the help button
    if (labelConfig.helpURL && labelConfig.helpURL !== '') {
      document.getElementById('ld_help').href = labelConfig.helpURL;
      document.getElementById('ld_help_wrap').hidden = false;
    }
    document.getElementById('labelName').innerHTML = labelConfig.labelName;

    ldThis.lineWidth.addEventListener('change', () => {
      if (ldThis.selectedMultiple.length > 0) {
        ldThis.selectedMultiple.forEach(item => item.strokeWidth(Number(ldThis.lineWidth.value)));
      } else {
        ldThis.selectedShape.strokeWidth(Number(ldThis.lineWidth.value));
      }
      ldThis.stage.draw();
    });

    ldThis.textButtons = {
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

    ldThis.outline = new Konva.Rect({
      x: 0,
      y: 0,
      width: 50,
      height: 50,
      dash: [10, 5],
      stroke: '#555555',
      strokeWidth: 1,
    });

    ldThis.imgUpDialog = new window.A11yDialog(document.getElementById('image-dialog-form'));
    ldThis.imgUpDialog.on('hide', () => {
      document.querySelector('#image-dialog-form .notice').setAttribute('style', 'display:none;');
      document.querySelector('form.upload-image').reset();
      document.querySelectorAll('[data-active]').forEach(elem => elem.dataset.active = 'false');
      document.querySelector('[data-action="select"]').dataset.active = 'true';
      document.querySelector('[data-action="select"]').focus();
    });

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
            ldThis.layer.add(recttmp);
            ldThis.tr.nodes([recttmp]);

            // reset draw mode
            ldThis.currentMode = 'select';
            ldThis.selectedShape = recttmp;
            // action?
            ldThis.stage.fire('ldSelectOne');
            ldThis.imgUpDialog.hide();
            ldThis.stage.draw();
            ldThis.selectedMultiple = [];
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

    ldThis.variableUI = {
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

    ldThis.textButtons.text.addEventListener('input', () => {
      const txtObj = resolveTextObject();
      txtObj.text(ldThis.textButtons.text.value);
      ldThis.stage.draw();
    });

    ldThis.textButtons.fontSize.addEventListener('change', () => {
      let txtObj;
      if (ldThis.selectedMultiple.length > 0) {
        ldThis.selectedMultiple.forEach((item) => {
          txtObj = resolveTextObject(item);
          txtObj.fontSize(Number(ldThis.textButtons.fontSize.value));
        });
      } else {
        txtObj = resolveTextObject();
        txtObj.fontSize(Number(ldThis.textButtons.fontSize.value));
      }
      ldThis.stage.draw();
    });

    ldThis.textButtons.fontFamily.addEventListener('change', () => {
      let txtObj;
      if (ldThis.selectedMultiple.length > 0) {
        ldThis.selectedMultiple.forEach((item) => {
          txtObj = resolveTextObject(item);
          txtObj.fontFamily(ldThis.textButtons.fontFamily.value);
        });
      } else {
        txtObj = resolveTextObject();
        txtObj.fontFamily(ldThis.textButtons.fontFamily.value);
      }
      ldThis.stage.draw();
    });

    /*
     * Build up a compound variable when the user presses the add or clear buttons.
     */
    ldThis.variableUI.compoundVars.addEventListener('click', (event) => {
      const elem = event.target.closest('[type=button]');
      if (!elem) {
        return;
      }
      if (ldThis.variableUI.compoundRes.value === '') {
        ldThis.variableUI.compoundRes.value = 'CMP:';
      }
      if (elem.name === 'add_compound_sel') {
        ldThis.variableUI.compoundDisp.textContent += ldThis.variableUI.compoundSel.selectr.getValue(true);
        ldThis.variableUI.compoundRes.value += `\${${ldThis.variableUI.compoundSel.selectr.getValue(true)}}`;
      }
      if (elem.name === 'add_compound_txt') {
        ldThis.variableUI.compoundDisp.textContent += ldThis.variableUI.compoundTxt.value;
        ldThis.variableUI.compoundRes.value += ldThis.variableUI.compoundTxt.value;
      }
      if (elem.name === 'clear_compound') {
        ldThis.variableUI.compoundDisp.textContent = '';
        ldThis.variableUI.compoundRes.value = 'CMP:';
      }
    });

    ldThis.stage = new Konva.Stage({
      container: 'paper',
      width: ((labelConfig.width !== undefined) ? (labelConfig.width - 1) * labelConfig.pxPerMm : 700),
      height: ((labelConfig.height !== undefined) ? (labelConfig.height - 1) * labelConfig.pxPerMm : 500),
    });
    ldThis.stage.on('dragstart', () => {
      if (ldThis.currentMode !== 'select') {
        ldThis.stage.stopDrag();
      }
    });
    ldThis.stage.on('ldSelectOne', () => {
      ldThis.selectedMultiple = [];
      ldThis.tr.enabledAnchors(['top-left', 'top-center', 'top-right', 'middle-right', 'middle-left',
        'bottom-left', 'bottom-center', 'bottom-right']);
      setSelectedButtons(true, textTypeSelected());
      setCopyButtons(true);
      setAlignButtons(false);
      if (lineTypeSelected()) {
        setLineButtons(true);
        if (ldThis.selectedShape.name() === 'line') {
          ldThis.tr.enabledAnchors(['middle-right', 'middle-left']);
        }
      } else {
        setLineButtons(false);
      }
      document.querySelector('#set-variable-opt').dataset.menu = 'off';
      if (textTypeSelected()) {
        setTextButtons(true);
        if (ldThis.selectedShape.name() === 'variableBox') {
          document.querySelector('#set-variable-opt').dataset.menu = 'on';
        }
      } else {
        setTextButtons(false);
      }

      // line thickness: line, rect, ellipse
      // bui, just, size, font, textarea: text, var
      // console.log('Selected one', ldThis.selectedShape);
    });
    ldThis.stage.on('ldSelectNone', () => {
      ldThis.tr.nodes([]);
      ldThis.stage.draw();
      ldThis.selectedShape = undefined;
      ldThis.selectedMultiple = [];
      setSelectedButtons(false);
      setLineButtons(false);
      setTextButtons(false);
      setCopyButtons(false);
      setAlignButtons(false);
      document.querySelector('#set-variable-opt').dataset.menu = 'off';
      // console.log('Selected none', ldThis.selectedShape);
    });
    ldThis.stage.on('ldSelectMultiple', () => {
      ldThis.tr.enabledAnchors(['top-left', 'top-center', 'top-right', 'middle-right', 'middle-left',
        'bottom-left', 'bottom-center', 'bottom-right']);
      setSelectedButtons(false);
      setLineButtons(false);
      // setTextButtons(false); // TODO: more nuanced - depends on what shapes have in common..
      setButtonsForMultiple();
      setAlignButtons(true);
      document.querySelector('#set-variable-opt').dataset.menu = 'off';
      // console.log('Selected multiple', ldThis.selectedMultiple);
    });

    ldThis.layer = new Konva.Layer();
    ldThis.layerVar = new Konva.Layer();
    // Set the drawing area's background to white.
    const konvaDiv = document.querySelector('div.konvajs-content');
    konvaDiv.classList.add('bg-white');
    ldThis.tr = new Konva.Transformer({ rotateEnabled: false });
    ldThis.tr.nodes([]);
    ldThis.layer.add(ldThis.tr);
    ldThis.stage.add(ldThis.layer);
    ldThis.stage.add(ldThis.layerVar);

    // clicks should select/deselect shapes
    ldThis.stage.on('click tap', (e) => {
      // if click on empty area - remove all selections
      if (e.target === ldThis.stage) {
        ldThis.stage.fire('ldSelectNone');
        return;
      }

      // // do nothing if clicked NOT on our rectangles
      // if (!e.target.hasName('rect')) {
      //   return;
      // }
      let target = e.target;
      const parentGroup = target.findAncestor('Group');
      if (parentGroup) {
        target = parentGroup;
      }

      // did we press shift or ctrl?
      const metaPressed = e.evt.shiftKey || e.evt.ctrlKey || e.evt.metaKey;
      const isSelected = ldThis.tr.nodes().indexOf(target) >= 0;

      ldThis.selectedShape = undefined;
      if (!metaPressed && !isSelected) {
        // if no key pressed and the node is not selected
        // select just one
        ldThis.tr.nodes([target]);
        ldThis.selectedShape = target;
        ldThis.stage.fire('ldSelectOne');
      } else if (metaPressed && isSelected) {
        // if we pressed keys and node was selected
        // we need to remove it from selection:
        const nodes = ldThis.tr.nodes().slice(); // use slice to have new copy of array
        // remove node from array
        nodes.splice(nodes.indexOf(target), 1);
        ldThis.tr.nodes(nodes);
        if (nodes.length === 1) {
          ldThis.selectedShape = nodes[0];
          ldThis.stage.fire('ldSelectOne');
        } else {
          ldThis.selectedMultiple = nodes;
          ldThis.stage.fire('ldSelectMultiple');
        }
      } else if (metaPressed && !isSelected) {
        // add the node into selection
        const nodes = ldThis.tr.nodes().concat([target]);
        ldThis.tr.nodes(nodes);
        ldThis.selectedMultiple = nodes;
        ldThis.stage.fire('ldSelectMultiple');
      }
      ldThis.layer.draw();
      ldThis.layerVar.draw();
    });

    ldThis.stage.on('contextmenu', (e) => {
      // prevent default behavior
      e.evt.preventDefault();
      if (e.target === ldThis.stage) {
        // if we are on empty place of the stage we will do nothing
        return;
      }
      if (ldThis.selectedMultiple.length > 0) {
        return;
      }
      const parentGroup = e.target.findAncestor('Group');
      if (!parentGroup || parentGroup.name() !== 'variableBox') {
        return;
      }

      // Make selection
      ldThis.tr.nodes([parentGroup]);
      ldThis.selectedShape = parentGroup;
      ldThis.stage.draw();
      ldThis.stage.fire('ldSelectOne');

      // show menu
      menuNode.style.display = 'initial';
      // const containerRect = ldThis.stage.container().getBoundingClientRect();
      // console.log('pos', ldThis.stage.getPointerPosition().x, containerRect.left);
      menuNode.style.top = `${ldThis.stage.getPointerPosition().y + 4}px`;
      menuNode.style.left = `${ldThis.stage.getPointerPosition().x + 4}px`;
      // menuNode.style.top = `${containerRect.top + ldThis.stage.getPointerPosition().y + 4}px`;
      // menuNode.style.left = `${containerRect.left + ldThis.stage.getPointerPosition().x + 4}px`;
      // console.log('style', menuNode.style);
    });
  };

  const ldCanvas = document.getElementById('paper');

  const saveVariableSettings = (variableTypeValue) => {
    const txtObj = ldThis.selectedShape.getChildren(node => node.getClassName() === 'Text')[0];
    const rectObj = ldThis.selectedShape.getChildren(node => node.getClassName() === 'Rect')[0];
    const varAttrs = {
      // fontSizePt: opts.fontSizePt || 8, // should this be looked-up? Only written on dump() ?
      whiteOnBlack: ldThis.variableUI.whiteOnBlack.checked,
      barcode: ldThis.variableUI.barcodeBool.checked,
      barcodeText: ldThis.variableUI.barcodeText.checked,
      barcodeTop: ldThis.variableUI.barcodeTop.value,
      barcodeWidthFactor: ldThis.variableUI.barcodeWidthFactor.value,
      barcodeMargin: ldThis.variableUI.barcodeMargin.value,
      barcodeSymbology: ldThis.variableUI.barcodeSymbology.value,
      staticValue: variableTypeValue === 'Static Barcode' ? ldThis.variableUI.staticInputValue.value : null,
    };
    if (txtObj.text() === 'Unset Variable' || ldThis.selectedShape.attrs.varType === txtObj.text()) {
      txtObj.text(variableTypeValue);
      ldThis.textButtons.text.value = variableTypeValue;
    }
    ldThis.selectedShape.attrs.varType = variableTypeValue;
    ldThis.selectedShape.attrs.varAttrs = varAttrs;
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
    ldThis.stage.draw();
  };

  const toggleBarcodeOptions = (checked) => {
    if (checked) {
      ldThis.variableUI.whiteOnBlack.checked = false;
      ldThis.variableUI.whiteOnBlack.disabled = true;
      ldThis.variableUI.barcodeOptions.style.display = 'block';
    } else {
      ldThis.variableUI.whiteOnBlack.disabled = false;
      ldThis.variableUI.barcodeOptions.style.display = 'none';
    }
  };

  const toggleErrorNotice = (show) => {
    if (show) {
      ldThis.variableUI.errBox.style.display = 'block';
    } else {
      ldThis.variableUI.errBox.style.display = 'none';
    }
  };

  const clearCompoundTexts = () => {
    ldThis.variableUI.compoundTxt.value = '';
    ldThis.variableUI.compoundRes.value = 'CMP:';
    ldThis.variableUI.compoundDisp.textContent = '';
  };

  const dialogSaveButton = () => {
    const noVarErr = 'Please ensure that a Variable type is saved';
    const noStaticErr = 'Please fill in text for a Static Barcode';
    const variableTypeValue = ldThis.variableUI.variableSelect.selectr.getValue(true);

    // console.log(variableTypeValue);
    if (variableTypeValue) {
      if (variableTypeValue === 'Static Barcode' && ldThis.variableUI.staticInputValue.value === '') {
        ldThis.variableUI.errBox.textContent = noStaticErr;
        toggleErrorNotice(true);
      } else {
        saveVariableSettings(variableTypeValue);
        // UndoRedoModule.registerUndoEvent();

        ldThis.variableUI.varDialog.hide();
        toggleErrorNotice(false);
      }
    } else {
      ldThis.variableUI.errBox.textContent = noVarErr;
      toggleErrorNotice(true);
    }
  };

  const varChange = (value) => {
    if (value === 'Static Barcode') {
      ldThis.variableUI.staticInput.style.display = 'flex';
      ldThis.variableUI.staticInputValue.required = true;
      ldThis.variableUI.barcodeBool.checked = true;
      toggleBarcodeOptions(true);
      ldThis.variableUI.barcodeBool.disabled = true;
      ldThis.variableUI.barcodeBoolWrapper.hidden = false;
      ldThis.variableUI.compoundVars.hidden = true;
      clearCompoundTexts();
    } else if (value === 'Compound Variable') {
      ldThis.variableUI.staticInputValue.required = false;
      ldThis.variableUI.staticInput.style.display = 'none';
      ldThis.variableUI.barcodeBool.disabled = false;
      ldThis.variableUI.barcodeBool.checked = false;
      ldThis.variableUI.barcodeBoolWrapper.hidden = true;
      toggleBarcodeOptions(false);
      ldThis.variableUI.compoundVars.hidden = false;
    } else {
      ldThis.variableUI.staticInputValue.required = false;
      ldThis.variableUI.staticInput.style.display = 'none';
      ldThis.variableUI.barcodeBool.disabled = false;
      ldThis.variableUI.barcodeBoolWrapper.hidden = false;
      ldThis.variableUI.compoundVars.hidden = true;
      clearCompoundTexts();
    }
  };

  const adjustWidth = (elem, width) => {
    let points;
    // VAR...
    if (elem.name() === 'line') {
      points = elem.points();
      if (points[0] !== points[2]) {
        points[2] += width;
        if (Math.abs(points[2] - points[0]) < ldThis.MIN_DIMENSION) {
          if (points[2] > points[0]) {
            points[2] = points[0] + ldThis.MIN_DIMENSION;
          } else {
            points[0] = points[2] + ldThis.MIN_DIMENSION;
          }
        }
        elem.points(points);
      }
    } else if (elem.name() === 'variableBox') {
      elem.width(elem.width() + width);
      if (elem.width() < ldThis.MIN_DIMENSION) {
        elem.width(ldThis.MIN_DIMENSION);
      }
      elem.getChildren().forEach(node => node.width(elem.width()));
    } else {
      elem.width(elem.width() + width);
      if (elem.width() < ldThis.MIN_DIMENSION) {
        elem.width(ldThis.MIN_DIMENSION);
      }
    }
  };

  const adjustHeight = (elem, height) => {
    let points;
    if (elem.name() === 'line') {
      points = elem.points();
      if (points[1] !== points[3]) {
        points[3] += height;
        if (Math.abs(points[3] - points[1]) < ldThis.MIN_DIMENSION) {
          if (points[3] > points[1]) {
            points[3] = points[1] + ldThis.MIN_DIMENSION;
          } else {
            points[1] = points[3] + ldThis.MIN_DIMENSION;
          }
        }
        elem.points(points);
      }
    } else if (elem.name() === 'variableBox') {
      elem.height(elem.height() + height);
      if (elem.height() < ldThis.MIN_DIMENSION) {
        elem.height(ldThis.MIN_DIMENSION);
      }
      elem.getChildren().forEach(node => node.height(elem.height()));
    } else {
      elem.height(elem.height() + height);
      if (elem.height() < ldThis.MIN_DIMENSION) {
        elem.height(ldThis.MIN_DIMENSION);
      }
    }
  };

  const shapeForClipboard = (shape) => {
    const marshal = new LdMarshal(shape);
    return marshal.dump();
  };

  const copyToClipboard = () => {
    ldThis.clipboard = { shapes: [] };
    ldThis.copyOffset = 5;

    if (ldThis.selectedShape) {
      ldThis.clipboard.shapes.push(shapeForClipboard(ldThis.selectedShape));
    } else {
      ldThis.selectedMultiple.forEach((elem) => {
        ldThis.clipboard.shapes.push(shapeForClipboard(elem));
      });
    }
    document.querySelector('[data-action="paste"]').disabled = false;
  };

  const pasteFromClipboard = () => {
    const newSelection = [];
    let marshal;

    ldThis.clipboard.shapes.forEach((shape) => {
      marshal = new LdMarshal(shape);
      newSelection.push(marshal.load(ldThis.copyOffset));
      ldThis.copyOffset += 5;
    });
    if (newSelection.length === 1) {
      ldThis.currentMode = 'select';
      ldThis.tr.nodes(newSelection);
      ldThis.selectedShape = newSelection[0];
    } else {
      ldThis.tr.nodes(newSelection);
      ldThis.selectedMultiple = newSelection;
    }
  };

  const getBackgroundImage = () => ldThis.layer.toDataURL();

  const showVariableDialog = () => {
    const curr = ldThis.selectedShape.attrs.varAttrs;
    const varType = ldThis.selectedShape.attrs.varType;

    ldThis.variableUI.varDialog.show();
    ldThis.variableUI.varForm.reset();
    ldThis.variableUI.variableSelect.selectr.setChoiceByValue(varType === 'unset' ? '' : varType);

    ldThis.variableUI.whiteOnBlack.checked = curr.whiteOnBlack;
    // fontSizePt: opts.fontSizePt || 8, // should this be looked-up? Only written on dump() ?
    ldThis.variableUI.barcodeBool.checked = curr.barcode;
    ldThis.variableUI.barcodeText.checked = curr.barcodeText;
    ldThis.variableUI.barcodeTop.value = curr.barcodeTop;
    ldThis.variableUI.barcodeWidthFactor.value = curr.barcodeWidthFactor;
    ldThis.variableUI.barcodeMargin.value = curr.barcodeMargin;
    ldThis.variableUI.barcodeSymbology.value = curr.barcodeSymbology;
    ldThis.variableUI.staticInputValue.value = curr.staticValue ? curr.staticValue : '';

    // Set the UI barcode show/hide state
    varChange(ldThis.selectedShape.varType);
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
    const holdSel = new Choices(ldThis.variableUI.variableSelect, {
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
    ldThis.variableUI.variableSelect.selectr = holdSel;

    ldThis.variableUI.variableSelect.addEventListener('change', (event) => {
      varChange(event.detail.value);
    });

    const holdCmpSel = new Choices(ldThis.variableUI.compoundSel, {
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
    ldThis.variableUI.compoundSel.selectr = holdCmpSel;

    document.querySelector('#variable-info-dialog-form button.save').addEventListener('click', () => {
      dialogSaveButton();
    });

    ldThis.variableUI.barcodeBool.addEventListener('change', function barcodeChange() {
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

      if (!ldThis.selectedShape && !ldThis.selectedMultiple.length > 0) {
        return null;
      }

      if (event.key === 'Delete' && ldThis.selectedShape) {
        ldThis.selectedShape.destroy();
        ldThis.stage.fire('ldSelectNone');
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
        if (ldThis.selectedMultiple.length > 0) {
          ldThis.selectedMultiple.forEach((elem) => {
            elem.move(move);
          });
        } else {
          ldThis.selectedShape.move(move);
        }
      }

      if (width) {
        if (ldThis.selectedMultiple.length > 0) {
          ldThis.selectedMultiple.forEach((elem) => {
            adjustWidth(elem, width);
          });
        } else {
          adjustWidth(ldThis.selectedShape, width);
        }
      }

      if (height) {
        if (ldThis.selectedMultiple.length > 0) {
          ldThis.selectedMultiple.forEach((elem) => {
            adjustHeight(elem, height);
          });
        } else {
          adjustHeight(ldThis.selectedShape, height);
        }
      }
      if (move || width || height) {
        ldThis.stage.draw();
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

    document.addEventListener('click', (event) => {
      let btn = event.target.closest('button[data-action]');
      let enable;

      if (btn) {
        if (btn.dataset.active) {
          document.querySelectorAll('[data-active]').forEach(elem => elem.dataset.active = 'false');
          btn.dataset.active = 'true';
        }
        if (btn.dataset.drawType) {
          ldThis.currentMode = 'draw';
          ldThis.currentDrawType = btn.dataset.drawType;
        } else {
          ldThis.currentMode = 'select';
          ldThis.currentDrawType = undefined;
        }
        if (btn.dataset.action === 'rotate' && ldThis.selectedShape) {
          ldThis.selectedShape.rotate(90);
          ldThis.stage.draw();
        }
        if (btn.dataset.action === 'remove' && ldThis.selectedShape) {
          ldThis.selectedShape.destroy();
          ldThis.stage.fire('ldSelectNone');
        }
        if (btn.dataset.action === 'copy' && (ldThis.selectedShape || ldThis.selectedMultiple.length > 0)) {
          copyToClipboard();
        }
        if (btn.dataset.action === 'paste') {
          pasteFromClipboard();
        }
        if (btn.dataset.image) {
          ldThis.imgUpDialog.show();
        }
      }

      btn = event.target.closest('button[data-textstyle]');
      if (btn) {
        enable = btn.dataset.selected === 'false';
        btn.dataset.selected = enable;
        if (ldThis.selectedMultiple.length > 0) {
          ldThis.selectedMultiple.forEach((item) => {
            applyTextStyle(enable, btn.dataset.textstyle, item);
          });
        } else {
          applyTextStyle(enable, btn.dataset.textstyle);
        }
        ldThis.stage.draw();
      }

      btn = event.target.closest('button[data-alignment]');
      if (btn) {
        document.querySelectorAll('button[data-alignment]').forEach(elem => elem.dataset.selected = 'false');
        btn.dataset.selected = 'true';
        if (ldThis.selectedMultiple.length > 0) {
          ldThis.selectedMultiple.forEach((item) => {
            applyTextAlignment(btn.dataset.alignment, item);
          });
        } else {
          applyTextAlignment(btn.dataset.alignment);
        }
        ldThis.stage.draw();
      }
    });
  });

  const getSelectedShape = () => ldThis.selectedShape;

  const getSelectedMultiple = () => ldThis.selectedMultiple;

  const align = (edge) => {
    let startPoint;

    if (ldThis.selectedMultiple.length === 0) {
      return 'Multiple shapes have not been selected';
    }

    if (edge === 'left') {
      if (ldThis.selectedMultiple[0].name() === 'line') {
        startPoint = ldThis.selectedMultiple[0].points()[0];
      } else if (ldThis.selectedMultiple[0].name() === 'ellipse') {
        startPoint = ldThis.selectedMultiple[0].x() - ldThis.selectedMultiple[0].radiusX();
      } else {
        startPoint = ldThis.selectedMultiple[0].x();
      }
      for (let i = 1; i < ldThis.selectedMultiple.length; i += 1) {
        if (ldThis.selectedMultiple[i].name() === 'line') {
          const points = ldThis.selectedMultiple[i].points();
          const shift = points[0] - startPoint;
          points[0] = startPoint;
          points[2] -= shift;
          ldThis.selectedMultiple[i].points(points);
        } else if (ldThis.selectedMultiple[i].name() === 'ellipse') {
          ldThis.selectedMultiple[i].move({ x: (startPoint - (ldThis.selectedMultiple[i].x() - ldThis.selectedMultiple[i].radiusX())), y: 0 });
        } else {
          ldThis.selectedMultiple[i].move({ x: (startPoint - ldThis.selectedMultiple[i].x()), y: 0 });
        }
      }
      ldThis.stage.draw();
    }

    if (edge === 'top') {
      if (ldThis.selectedMultiple[0].name() === 'line') {
        startPoint = ldThis.selectedMultiple[0].points()[1];
      } else if (ldThis.selectedMultiple[0].name() === 'ellipse') {
        startPoint = ldThis.selectedMultiple[0].y() - ldThis.selectedMultiple[0].radiusY();
      } else {
        startPoint = ldThis.selectedMultiple[0].y();
      }
      for (let i = 1; i < ldThis.selectedMultiple.length; i += 1) {
        if (ldThis.selectedMultiple[i].name() === 'line') {
          const points = ldThis.selectedMultiple[i].points();
          const shift = points[1] - startPoint;
          points[1] = startPoint;
          points[3] -= shift;
          ldThis.selectedMultiple[i].points(points);
        } else if (ldThis.selectedMultiple[i].name() === 'ellipse') {
          ldThis.selectedMultiple[i].move({ x: 0, y: (startPoint - (ldThis.selectedMultiple[i].y() - ldThis.selectedMultiple[i].radiusY())) });
        } else {
          ldThis.selectedMultiple[i].move({ x: 0, y: (startPoint - ldThis.selectedMultiple[i].y()) });
        }
      }
      ldThis.stage.draw();
    }
  };

  const getCurrentMode = () => ldThis.currentMode;

  const getCurrentDrawType = () => ldThis.currentDrawType;

  const drawStarter = () => {
    const rect1 = new Konva.Rect({
      x: 20,
      y: 20,
      width: 100,
      height: 50,
      fill: 'green',
      stroke: 'black',
      name: 'Green',
      strokeWidth: 4,
    });
    // add the shape to the layer
    ldThis.layer.add(rect1);

    const rect2 = new Konva.Rect({
      x: 150,
      y: 40,
      width: 100,
      height: 50,
      fill: 'red',
      name: 'Red',
      shadowBlur: 10,
      cornerRadius: 10,
    });
    ldThis.layer.add(rect2);

    const rect3 = new Konva.Rect({
      x: 50,
      y: 120,
      width: 100,
      height: 100,
      fill: 'blue',
      name: 'Blue',
      cornerRadius: [0, 10, 20, 30],
    });
    ldThis.layer.add(rect3);

    ldThis.stage.draw();
  };

  const drawExtra = () => {
    const shape = new LdText(220, 220, 80, 50);
    const recttmp = shape.generate({ text: 'A test', fontFamily: 'Lato Light' });
    ldThis.layer.add(recttmp);
    ldThis.stage.draw();
  };

  const drawNew = (x, y, x2, y2) => {
    let recttmp;
    let shape;
    let startX = x;
    let startY = y;
    let endX = x2;
    let endY = y2;
    ldThis.tr.enabledAnchors(['top-left', 'top-center', 'top-right', 'middle-right', 'middle-left', 'bottom-left', 'bottom-center', 'bottom-right']);

    // Always define from left to right, top to bottom
    if (startX > endX) {
      [startX, endX] = [endX, startX];
    }
    if (startY > endY) {
      [startY, endY] = [endY, startY];
    }

    if (startX === endX) {
      if (endY - startY < ldThis.MIN_DIMENSION) {
        endY = startY + ldThis.MIN_DIMENSION;
      }
    } else if (startY === endY) {
      if (endX - startX < ldThis.MIN_DIMENSION) {
        endX = startX + ldThis.MIN_DIMENSION;
      }
    } else {
      if (endX - startX < ldThis.MIN_DIMENSION) {
        endX = startX + ldThis.MIN_DIMENSION;
      }
      if (endY - startY < ldThis.MIN_DIMENSION) {
        endY = startY + ldThis.MIN_DIMENSION;
      }
    }

    if (ldThis.currentDrawType === 'Ellipse') {
      shape = new LdEllipse(startX, startY, endX - startX, endY - startY);
      recttmp = shape.generate();
    } else if (ldThis.currentDrawType === 'TextBox') {
      shape = new LdText(startX, startY, endX - startX, endY - startY);
      recttmp = shape.generate();
    } else if (ldThis.currentDrawType === 'VariableBox') {
      shape = new LdVariable(startX, startY, endX - startX, endY - startY);
      recttmp = shape.generate();
    } else if (ldThis.currentDrawType === 'Line') {
      shape = new LdLine(startX, startY, endX - startX, endY - startY, endX, endY);
      recttmp = shape.generate();
      if (startY === endY) {
        ldThis.tr.enabledAnchors(['middle-left', 'middle-right']);
      } else {
        ldThis.tr.enabledAnchors(['top-center', 'bottom-center']);
      }
    } else {
      shape = new LdRect(startX, startY, endX - startX, endY - startY);
      recttmp = shape.generate();
    }
    if (ldThis.currentDrawType === 'VariableBox') {
      ldThis.layerVar.add(recttmp);
    } else {
      ldThis.layer.add(recttmp);
    }
    ldThis.tr.nodes([recttmp]);

    ldThis.stage.draw();

    ldThis.currentMode = 'select';
    ldThis.selectedShape = recttmp;
    ldThis.stage.fire('ldSelectOne');

    // set select button to active
    document.querySelectorAll('[data-active]').forEach(elem => elem.dataset.active = 'false');
    document.querySelector('[data-action="select"]').dataset.active = 'true';

    if (ldThis.currentDrawType === 'TextBox') {
      document.querySelector('#ldSave').focus();
      ldThis.textButtons.text.select();
    }
    ldThis.currentDrawType = undefined;
  };
  // END of example...

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
  ldCanvas.addEventListener('mousedown', (event) => {
    // TODO: Look at: https://konvajs.org/docs/sandbox/Relative_Pointer_Position.html
    // - for using Stage to get x/y...
    [startX, startY] = getCoords(event);
    if (ldThis.currentMode !== 'select') {
      ldThis.outline.x(startX);
      ldThis.outline.y(startY);
      ldThis.layer.add(ldThis.outline);
    }
    // console.log('starting', startX, startY);
  });
  ldCanvas.addEventListener('mousemove', (event) => {
    // Might want to debounce...
    let tmpX;
    let tmpY;
    if (ldThis.currentMode !== 'select') {
      [tmpX, tmpY] = getCoords(event);
      ldThis.outline.width(tmpX - startX);
      ldThis.outline.height(tmpY - startY);
      ldThis.layer.draw();
    }
  });
  ldCanvas.addEventListener('mouseup', (event) => {
    if (ldThis.currentMode !== 'select') {
      ldThis.outline.remove();

      [endX, endY] = getCoords(event);
      if (ldThis.currentDrawType === 'Line') {
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
      width: ldThis.stage.width(),
      height: ldThis.stage.height(),
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
          // fontSizePt: shape.attrs.fontSizePt, // settings.fontSizePt = fontSizes[shape.textBox.fontSize()];
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

  const load = (strConfig) => {
    let marshal;

    let config = typeof strConfig === 'string' ? JSON.parse(strConfig) : strConfig;
    if (!config.version) {
      config = convert(strConfig);
    }

    // let shape;
    // let item;
    config.nodes.forEach((node) => {
      marshal = new LdMarshal(node);
      marshal.load();
    });

    ldThis.stage.draw();
  };

  const hasUnsetVariables = () => ldThis.layerVar.getChildren().some(item => item.attrs.varType === 'unset');

  const changesMade = () => ldThis.changesMade;

  const renumberVariables = () => {
    let pos;
    let varNum;
    const items = ldThis.layerVar.getChildren().filter(item => item.attrs.varType !== 'Static Barcode').map(item => item.attrs.varNum).sort();
    // console.log(items);
    if (items.length === 0) { return; }

    const seqs = Array(items.length).fill().map((_, idx) => 1 + idx);
    // console.log(items, seqs);
    if (items.every((a, i) => a === seqs[i])) { return; }

    ldThis.layerVar.getChildren().filter(item => item.attrs.varType !== 'Static Barcode').forEach((item) => {
      varNum = item.attrs.varNum;
      pos = items.indexOf(varNum);
      if (seqs[pos] !== varNum) {
        item.attrs.varNum = seqs[pos];
      }
    });
    // make a range same length as items.
    // sort items
    // if identical, nothing to do
    // else change variables' varNum to correct position value.
    // 1st arr.index at varNum -> get value from 2nd index at same position.
  };

  // Dump the canvas' shapes to a JSON object.
  const dump = () => {
    let marshal;

    renumberVariables();

    const jsonOut = {
      version: 1,
      width: ldThis.stage.width(),
      height: ldThis.stage.height(),
      nodes: [],
    };

    ldThis.layerVar.getChildren().forEach((item) => {
      if (item.name() === 'variableBox') {
        marshal = new LdMarshal(item);
        jsonOut.nodes.push(marshal.dump());
      }
    });

    ldThis.layer.getChildren().forEach((item) => {
      if (item.getClassName() === 'Transformer') {
        return;
      }
      marshal = new LdMarshal(item);
      jsonOut.nodes.push(marshal.dump());
    });

    // return JSON.stringify(jsonOut);
    return jsonOut;
  };

  const saveLabel = () => {
    // make fetch call...
    // MyLabel.fixIds();
    // const keyValues = MyLabel.exportToJSON(labelConfig.labelName);
    const form = new FormData();
    form.append('labelName', ldThis.labelConfig.labelName);
    form.append('labelDimension', ldThis.labelConfig.labelDimension);
    form.append('pixelPerMM', ldThis.labelConfig.pxPerMm);
    form.append('label', JSON.stringify(dump()));
    // form.append('XMLString', ' this.generateXMLFile(),');
    form.append('imageString', getBackgroundImage());
    form.append('labelWidth', ldThis.labelConfig.width);
    form.append('labelHeight', ldThis.labelConfig.height);
    // Object.keys(keyValues).forEach((attr) => {
    //   form.append(attr, keyValues[attr]);
    // });
    form.append('_csrf', document.querySelector('meta[name="_csrf"]').content);

    fetch(ldThis.savePath, {
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
          ldThis.changesMade = false;
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

  document.querySelector('#ldSave').addEventListener('click', () => {
    saveLabel();
  });

  const debug = () => {
    let no;
    let fno;
    let nm;
    let txtObj;
    const nodes = ldThis.layer.getChildren().map((item) => {
      nm = item.name();
      return `<li>${item._id} - ${nm || item.getClassName()}</li>`; // eslint-disable-line no-underscore-dangle
    });
    ldThis.layerVar.getChildren().forEach((item) => {
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

  // Canvas.container().addEventListener('mousedown', (event) => {
  //   DrawApp.drawStart(event);
  // });
  // Canvas.container().addEventListener('mouseup', () => {
  //   DrawApp.drawEnd();
  // });

  return {
    init,
    getSelectedShape,
    getSelectedMultiple,
    getCurrentMode,
    getCurrentDrawType,
    drawStarter,
    drawExtra,
    align,
    debug,
    dump,
    load,
    convert,
    getBackgroundImage, // variables on different layer....
    renumberVariables,
    hasUnsetVariables,
    changesMade,
  };
}());

// const labelConfig = {
//   labelName: 'A test Label',
//   width: 100,
//   height: 100,
//   pxPerMm: 8,
//   // helpURL: '/help/system/rmd/rmd_properties', // PART OF OPTIONS MENU?
// };
//
// LabelDesigner.init(labelConfig);
