/* exported crossbeamsUtils */

/**
 * General utility functions for Crossbeams.
 * @namespace
 */
const crossbeamsUtils = {

  currentDialogLevel: function currentDialogLevel() {
    if (crossbeamsDialogLevel2.shown) {
      return 2;
    }
    if (crossbeamsDialogLevel1.shown) {
      return 1;
    }
    return 0;
  },

  nextDialogContent: function nextDialogContent() {
    switch (this.currentDialogLevel()) {
      case 2:
        return 'dialog-content-level2';
      case 1:
        return 'dialog-content-level2';
      default:
        return 'dialog-content-level1';
    }
  },

  nextDialogTitle: function nextDialogTitle() {
    switch (this.currentDialogLevel()) {
      case 2:
        return 'dialogTitleLevel2';
      case 1:
        return 'dialogTitleLevel2';
      default:
        return 'dialogTitleLevel1';
    }
  },

  nextDialog: function nextDialog() {
    switch (this.currentDialogLevel()) {
      case 2:
        return crossbeamsDialogLevel2;
      case 1:
        return crossbeamsDialogLevel2;
      default:
        return crossbeamsDialogLevel1;
    }
  },

  activeDialogContent: function activeDialogContent() {
    switch (this.currentDialogLevel()) {
      case 2:
        return 'dialog-content-level2';
      case 1:
        return 'dialog-content-level1';
      default:
        return 'dialog-content-level1';
    }
  },

  activeDialogTitle: function activeDialogTitle() {
    switch (this.currentDialogLevel()) {
      case 2:
        return 'dialogTitleLevel2';
      case 1:
        return 'dialogTitleLevel1';
      default:
        return 'dialogTitleLevel1';
    }
  },

  activeDialog: function activeDialog() {
    switch (this.currentDialogLevel()) {
      case 2:
        return crossbeamsDialogLevel2;
      case 1:
        return crossbeamsDialogLevel1;
      default:
        return crossbeamsDialogLevel1;
    }
  },

  recordGridIdForPopup: function recordGridIdForPopup(gridId) {
    let key = '';
    switch (this.currentDialogLevel()) {
      case 2:
        key = 'level2PopupOnGrid';
        break;
      case 1:
        key = 'level1PopupOnGrid';
        break;
      default:
        key = 'level0PopupOnGrid';
    }
    crossbeamsLocalStorage.setItem(key, gridId);
  },

  currentGridIdForPopup: function currentGridIdForPopup() {
    let key = '';
    switch (this.currentDialogLevel()) {
      case 2:
        key = 'level2PopupOnGrid';
        break;
      case 1:
        key = 'level1PopupOnGrid';
        break;
      default:
        key = 'level0PopupOnGrid';
    }
    return crossbeamsLocalStorage.getItem(key);
  },

  baseGridIdForPopup: function baseGridIdForPopup() {
    let key = '';
    switch (this.currentDialogLevel()) {
      case 2:
        key = 'level1PopupOnGrid';
        break;
      case 1:
        key = 'level0PopupOnGrid';
        break;
      default:
        key = 'level0PopupOnGrid';
    }
    return crossbeamsLocalStorage.getItem(key);
  },

  // Popup a modal dialog.
  /**
   * Show a popup dialog window and make an AJAX call to populate the dialog.
   * @param {string} title - the title to show in the dialog.
   * @param {string} href - the url to call to load the dialog main content.
   * @returns {void}
   */
  popupDialog: function popupDialog(title, href) {
    document.getElementById(this.nextDialogTitle()).innerHTML = title;
    document.getElementById(this.nextDialogContent()).innerHTML = '';
    fetch(href, {
      method: 'GET',
      headers: new Headers({
        'X-Custom-Request-Type': 'Fetch',
      }),
      credentials: 'same-origin',
    }).then(response => response.text())
      .then((data) => {
        const dlg = document.getElementById(this.activeDialogContent());
        dlg.innerHTML = data;
        crossbeamsUtils.makeMultiSelects();
        crossbeamsUtils.makeSearchableSelects();
        const grids = dlg.querySelectorAll('[data-grid]');
        grids.forEach((grid) => {
          const gridId = grid.getAttribute('id');
          const gridEvent = new CustomEvent('gridLoad', { detail: gridId });
          document.dispatchEvent(gridEvent);
        });
        const sortable = Array.from(dlg.getElementsByTagName('input')).filter(a => a.dataset && a.dataset.sortablePrefix);
        if (sortable.length > 0) {
          crossbeamsUtils.makeListSortable(sortable[0].dataset.sortablePrefix);
        }
      }).catch((data) => {
        Jackbox.error('The action was unsuccessful...');
        const htmlText = data.responseText ? data.responseText : '';
        document.getElementById(this.activeDialogContent()).innerHTML = htmlText;
      });
    this.nextDialog().show();
  },

  /**
   * Close the popup dialog window.
   * @returns {void}
   */
  closePopupDialog: function closePopupDialog() {
    this.activeDialog().hide();
  },

  /**
   * Show a popup dialog window with the provided title and text.
   * @param {string} title - the title to show in the dialog.
   * @param {string} text - the text to serve as the main body of the dialog.
   * @returns {void}
   */
  showHtmlInDialog: function showHtmlInDialog(title, text) {
    document.getElementById(this.nextDialogTitle()).innerHTML = title;
    document.getElementById(this.nextDialogContent()).innerHTML = text;
    this.nextDialog().show();
  },

  /**
   * Applies the multi skin to multiselect dropdowns.
   * @returns {void}
   */
  makeMultiSelects: function makeMultiSelects() {
    const sels = document.querySelectorAll('[data-multi]');
    sels.forEach((sel) => {
      multi(sel); // multi select with two panes...
    });
  },

  /**
   * Changes select tags into Selectr elements.
   * @returns {void}
   */
  makeSearchableSelects: function makeSearchableSelects() {
    const sels = document.querySelectorAll('.searchable-select');
    let holdSel;
    sels.forEach((sel) => {
      holdSel = new Selectr(sel, {
        customClass: 'cbl-input',
        defaultSelected: true, // should configure via data...
        // multiple: true,     // should configure via data...
        allowDeselect: false,
        clearable: true,       // should configure via data...
      }); // select that can be searched.

      // TODO: Split this up into modular pieces based on rules in data- attributes...
      if (sel.dataset && sel.dataset.changeValues) {
        holdSel.on('selectr.change', (option) => {
          sel.dataset.changeValues.split(',').forEach((el) => {
            const target = document.getElementById(el);
            if (target && (target.dataset && target.dataset.enableOnValues)) {
              const vals = target.dataset.enableOnValues;
              if (_.includes(vals, option.value)) {
                target.disabled = false;
              } else {
                target.disabled = true;
              }
            }
          });
        });
      }
    });
  },

  /**
   * Toggle the visibility of en element in the DOM:
   * @param {string} id - the id of the DOM element.
   * @param {elelment} [button] - optional. Button to add the pure-button-active class (Pure.css)
   * @returns {void}
   */
  toggleVisibility: function toggleVisibility(id, button) {
    const e = document.getElementById(id);

    if (e.style.display === 'block') {
      e.style.display = 'none';
      if (button !== undefined) {
        button.classList.remove('pure-button-active');
      }
    } else {
      e.style.display = 'block';
      if (button !== undefined) {
        button.classList.add('pure-button-active');
      }
    }
  },

  /**
   * alert() Shows a SweetAlert2 info alert dialog.
   * @param {string} prompt - the prompt text.
   * @param {string} [title] - optional title for the dialog.
   * @returns {void}
   */
  alert: function alert({ prompt, title, type = 'info' }) {
    swal({
      title: title === undefined ? '' : title,
      text: prompt,
      type,
    }).catch(swal.noop);
  },

  /**
   * confirm() Shows a SweetAlert2 warning dialog asking the user to confirm or cancel.
   * @param {string} prompt - the prompt text.
   * @param {string} [title] - optional title for the dialog.
   * @param {function} okFunc - the function to call when the user presses OK.
   * @param {function} [cancelFunc] - optional function to call if the user presses cancel.
   * @returns {void}
   */
  confirm: function confirm({ prompt, title, okFunc, cancelFunc }) {
    // console.log(title);
    swal({
      title: title === undefined ? '' : title,
      text: prompt,
      type: 'warning',
      showCancelButton: true }).then(okFunc, cancelFunc).catch(swal.noop);
  },

  /**
   * Return the character code of an event.
   * @param {event} evt - the event.
   * @returns {string} - the keyCode.
   */
  getCharCodeFromEvent: function getCharCodeFromEvent(evt) {
    const event = evt || window.event;
    return (event.which === 'undefined')
      ? event.keyCode
      : event.which;
  },

  /**
   * Is a character numeric?
   * @param {string} charStr - the character string.
   * @returns {boolean} - true if the string is numeric, false otherwise.
   */
  isCharNumeric: function isCharNumeric(charStr) {
    return !!(/\d/.test(charStr));
  },

  /**
   * Check if the user pressed a numeric key.
   * @param {event} event - the event.
   * @returns {boolean} - true if the key represents a number.
   */
  isKeyPressedNumeric: function isKeyPressedNumeric(event) {
    const charCode = this.getCharCodeFromEvent(event);
    const charStr = String.fromCharCode(charCode);
    return this.isCharNumeric(charStr);
  },

  /**
   * Make a select tag using an array for the options.
   * The Array can be an Array of Arrays too.
   * For a 1-dimensional array the option text and value are the same.
   * For a 2-dimensional array the option text is the 1st element and the value is the second.
   * @param {string} name - the name of the select tag.
   * @param {array} arr - the array of option values.
   * @param {string} [attrs] - optional - a string to include class/style etc in the tag.
   * @returns {string} - the select tag code.
   */
  makeSelect: function makeSelect(name, arr, attrs) {
    // var sel = '<select id="' + name + '" name="' + name + '">';
    let sel = `<select id="${name}" name="${name}" ${attrs || ''}>`;
    arr.forEach((item) => {
      if (item.constructor === Array) {
        // sel += '<option value="' + (item[1] || item[0]) + '">' + item[0] + '</option>';
        sel += `<option value="${(item[1] || item[0])}">${item[0]}</option>`;
      } else {
        // sel += '<option value="' + item + '">' + item + '</option>';
        sel += `<option value="${item}">${item}</option>`;
      }
    });
    sel += '</select>';
    return sel;
  },

  /**
   * Adds a parameter named "json_var" to a form
   * containing a stringified version of the passed object.
   * @param {string} formId - the id of the form to be modified.
   * @param {object} jsonVar - the object to be added to the form as a string.
   * @returns {void}
   */
  addJSONVarToForm: function addJSONVarToForm(formId, jsonVar) {
    const form = document.getElementById(formId);
    const element1 = document.createElement('input');
    element1.type = 'hidden';
    element1.value = JSON.stringify(jsonVar);
    element1.name = 'json_var';
    form.appendChild(element1);
  },

  /**
   * Return the index of an LI node in a UL/OL list.
   * @param {element} node - the li node.
   * @returns {integer} - the index of the selected node.
   */
  getListIndex: function getListIndex(node) {
    const childs = node.parentNode.children; // childNodes;
    let i = 0;
    let index;
    Array.from(childs).forEach((child) => {
      i += 1;
      if (node === child) {
        index = i;
      }
    });
    return index;
  },

  /**
   * Make a list sortable.
   * @param {string} prefix - the prefix part of the id of the ol or ul tag.
   * @returns {void}
   */
  makeListSortable: function makeListSortable(prefix) {
    const el = document.getElementById(`${prefix}-sortable-items`);
    const sortedIds = document.getElementById(`${prefix}-sorted_ids`);
    Sortable.create(el, {
      animation: 150,
      handle: '.crossbeams-drag-handle',
      ghostClass: 'crossbeams-sortable-ghost',  // Class name for the drop placeholder
      dragClass: 'crossbeams-sortable-drag',  // Class name for the dragging item
      onEnd: () => {
        const idList = [];
        Array.from(el.children).forEach((child) => { idList.push(child.id.replace('si_', '')); });// strip si_ part...
        sortedIds.value = idList.join(',');
      },
    });
  },

};
