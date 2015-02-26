/**
 * autocomplete.js 1.0.0
 * jQuery plugin
 * Remake of the complete-ly.js (c) by Lorenzo Puccetti - 2013
 *
 * MIT Licensing
 * Copyright (c) 2015 Piotr Aleksander Styczynski
 *
 * This Software shall be used for doing good things, not bad things.
 *                  - Lorenzo Puccetti
 *
 * This is a simple autocomple library.
 * The autocomple.js supports dynamic suggestions and history browsing.
 * To set up autocomplete just use jQuery $('#div').autocomplete({ options: ["apple", "bannana", "strawberry", "pineapple"] })
 *
 * You can easily manipulate the suggestions list and history directly:
 *
 * var ac = $('#div').autocomplete({ options: ["apple", "bannana", "strawberry", "pineapple"] });
 * ac.options = ["nope"]; //override suggestions list
 * ac.historyInput = []; //clear history
 *
 **/

jQuery.fn.extend({

	autocomplete: function(settings) {
		container = this;
    if(settings == null || settings == {} || settings == undefined) {
      return container.__autocomplete__;
    }

		settings = settings || {};
    settings.inputWidth = settings.inputWidth || '100%';
		settings.dropDownWidth = settings.dropDownWidth || '50%';
		settings.fontSize = settings.fontSize || null;
		settings.fontFamily = settings.fontFamily || null;
		settings.formPromptHTML = settings.formPromptHTML || '';
		settings.color = settings.color || null;
		settings.hintColor = settings.hintColor || null;
		settings.backgroundColor = settings.backgroundColor || null;
		settings.dropDownBorderColor = settings.dropDownBorderColor || null;
		settings.dropDownZIndex = settings.dropDownZIndex || '100';
		settings.dropDownOnHoverBackgroundColor = settings.dropDownOnHoverBackgroundColor || null;
    settings.enableHistory = settings.enableHistory || true;
    settings.inputHistory = settings.inputHistory || [];
    settings.classes = {} || settings.classes;
    settings.classes.input = settings.classes.input || null;
    settings.classes.dropdown = settings.classes.input || null;
    settings.classes.hint = settings.classes.input || null;
    settings.classes.wrapper = settings.classes.input || null;
    settings.classes.prompt = settings.classes.input || null;
    settings.classes.hoverItem = settings.classes.input || null;
    settings.classes.row = settings.classes.input || null;
    settings.maxSuggestionsCount = settings.maxSuggestionsCount || 100;
    settings.suggestionBoxHeight = settings.suggestionBoxHeight || '75px';
    settings.showDropDown = settings.showDropDown || false;
		settings.options = settings.options || {};


		var formInput = $('<input class="autocomplete autocomplete-input" type="text" spellcheck="false"></input>')
      .css('width', settings.inputWidth)
		  .css('outline', '0')
		  .css('border', '0')
		  .css('margin', '0')
	    .css('padding', '0')
      .css('backgroundColor', 'transparent')
  		.css('verticalAlign', 'top')
  		.css('position', 'relative')
      .css('background', 'transparent')
      .addClass(settings.classes.input);


		var formHint = formInput.clone()
      .css('width', settings.inputWidth)
		  .attr('disabled', '')
		  .css('position', 'absolute')
		  .css('top', 'inherit')
		  .css('left', 'inherit')
		  .css('borderColor', 'transparent')
		  .css('boxShadow', 'none')
		  .css('color', settings.hintColor)
      .addClass('autocomplete-hint')
      .addClass(settings.classes.hint);

		var formWrapper = $('<div class="autocomplete autocomplete-wrapper"></div>')
      .css('width', settings.inputWidth)
		  .css('position', 'relative')
		  .css('outline', '0')
		  .css('border', '0')
		  .css('margin', '0')
		  .css('padding', '0')
		  .css('paddingTop', '10px')
      .addClass(settings.classes.wrapper);

		var formPrompt = $('<div class="autocomplete autocomplete-prompt"></div>')
		  .css('position', 'absolute')
		  .css('outline', '0')
		  .css('margin', '0')
		  .css('padding', '0')
		  .css('border', '0')
		  .css('top', '0')
		  .css('left', '0')
		  .css('overflow', 'hidden')
		  .html(settings.formPromptHTML)
      .addClass(settings.classes.prompt);

		if ($('body') === undefined) {
			throw 'document.body is undefined. The library was wired up incorrectly.';
		}
		$('body').append(formPrompt);

		var w = formPrompt.width();
		formWrapper.append(formPrompt);

		formPrompt
      .show()
		  .css('left', '-' + w + 'px')
		  .css('marginLeft', w + 'px');

		var dropDown = $('<div class="autocomplete autocomplete-dropdown"></div>')
		  .css('position', 'relative')
		  .hide()
		  .css('outline', '0')
		  .css('margin', '0')
		  .css('padding', '0')
		  .css('text-align', 'left')
		  .css('font-size', settings.fontSize)
		  .css('font-family', settings.fontFamily)
		  .css('max-height', settings.suggestionBoxHeight)
		  .css('background-color', settings.backgroundColor)
		  .css('z-index', settings.dropDownZIndex)
		  .css('cursor', 'default')
		  .css('border-style', 'solid')
		  .css('border-width', '1px')
		  .css('border-color', settings.dropDownBorderColor)
		  .css('overflow-x', 'hidden')
		  .css('white-space', 'pre')
		  .css('overflow-y', 'scroll')
		  .css('height', settings.suggestionBoxHeight)
			.css('width', settings.dropDownWidth)
      .addClass(settings.classes.dropdown);

		var createDropDownController = function(elem) {
			var rows = [];
			var ix = 0;
			var oldIndex = -1;

			var onMouseOver = function() {
				$(this).css('outline', '1px solid #ddd');
			}
			var onMouseOut = function() {
				$(this).css('outline', '0');
			}
			var onMouseDown = function() {
				p.hide();
				p.onMouseSelected(this.__hint);
			}

			var p = {
				hide: function() {
					elem.hide();
				},
				refresh: function(token, array) {
					elem.hide();
					ix = 0;
					elem.html("");
					var vph = (window.innerHeight || document.documentElement.clientHeight);
					var distanceToTop = elem.offset().top - 6;
					var distanceToBottom = vph - (elem.parent().height() - elem.height() - elem.offset().top) - 6;

					rows = [];
					var maxOptionsCount = 100;
					var curOptionsCount = 0;
					for (var i = 0; i < array.length; i++) {
						if (array[i].toLowerCase().indexOf(token.toLowerCase()) === 0) {
              ++curOptionsCount;
  						if (curOptionsCount > settings.maxSuggestionsCount) {
  							break;
  						}
  						var divRow = $('<div></div>')
                .css('color', settings.color)
  						  .mouseover(onMouseOver)
  						  .mouseout(onMouseOut)
  						  .mousedown(onMouseDown)
                .addClass(settings.classes.row);

              divRow[0].__hint = divRow.__hint = array[i];
  						divRow.html(token + '<b>' + array[i].substring(token.length) + '</b>');
  						rows.push(divRow);
  						elem.append(divRow);
            }
					}
					if (rows.length === 0) {
						return;
					}
					if (rows.length === 1 && token === rows[0].__hint) {
						return;
					}

					if (rows.length < 2) return;
					p.highlight(0);

					if (distanceToTop > distanceToBottom * 3) {
						elem
              .css('maxHeight', distanceToTop + 'px')
						  .css('top', '')
						  .css('bottom', '100%');
					} else {
						elem
              .css('top', '100%')
						  .css('bottom', '')
						  .css('maxHeight', distanceToBottom + 'px');
					}
					elem.show();
				},
				highlight: function(index) {
					if (oldIndex != -1 && rows[oldIndex]) {
						rows[oldIndex].css('backgroundColor', settings.backgroundColor);
					}
          dropDown.find(settings.classes.hoverItem).removeClass(settings.classes.hoverItem);
          dropDown.find('.autocomplete-hover-item').removeClass('autocomplete-hover-item');
					rows[index].css('backgroundColor', settings.dropDownOnHoverBackgroundColor);
          rows[index].addClass(settings.classes.hoverItem);
          rows[index].addClass('autocomplete-hover-item');
					oldIndex = index;
				},
				move: function(step) {
					if (!elem.is(':visible')) return '';
					if (ix + step === -1 || ix + step === rows.length) return rows[ix].__hint;
					ix += step;
					p.highlight(ix);
					dropDown.scrollTop(dropDown.scrollTop() + step * dropDown.children().height());
					return rows[ix].__hint;
				},
				onMouseSelected: function() {}
			};
			return p;
		}

		var dropDownController = createDropDownController(dropDown);

		dropDownController.onMouseSelected = function(text) {
			formInput.val(leftSide + text);
			formHint.val(leftSide + text);
			rs.onChange(formInput.val());
			registerOnTextChangeOldValue = formInput.val();
			setTimeout(function() {
				formInput.focus();
			}, 0);
		}

    if(!settings.showDropDown) {
      dropDown.css('visibility', 'hidden');
      dropDown.css('display', 'none');
    } else {
      formWrapper.append(dropDown);
    }
		formWrapper.append(formHint);
		formWrapper.append(formInput);

		container.append(formWrapper);

		var spacer;
		var leftSide;

		function calculateWidthForText(text) {
			if (spacer === undefined) {
				spacer = $('<span></span>')
			    .hide()
				  .css('position', 'fixed')
				  .css('outline', '0')
				  .css('margin', '0')
				  .css('padding', '0')
				  .css('border', '0')
				  .css('left', '0')
				  .css('white-space', 'pre')
				  .css('font-size', settings.fontSize)
				  .css('font-family', settings.fontFamily)
				  .css('font-weight', 'normal');
				$("body").append(spacer);
			}

			spacer.text(text);
			return spacer.width();
		}


		var rs = {
			onArrowDown: function() {},
			onArrowUp: function() {},
			onEnter: function() {
        this.inputHistory.push(formInput.val());
      },
			onTab: function() {},
			onChange: function() {
				rs.repaint();
			},
      onHistoryPrev: function() {
        formInput.val(this.historyNavigatePrev());
      },
      onHistoryNext: function() {
        formInput.val(this.historyNavigateNext());
      },
      getInputHistory: function() {
        return this.inputHistory;
      },
			startFrom: 0,
			options: settings.options,
      inputHistory: settings.inputHistory,
      historyIndex: 0,
      historyBrowsingActive: false,
			formWrapper: formWrapper,
			input: formInput,
			hint: formHint,
			dropDown: dropDown,
			formPrompt: formPrompt,
      historyNavigateNext: function() {
        this.historyIndex++;
        if(this.historyIndex >= this.inputHistory.length) {
          this.historyIndex = this.inputHistory.length - 1;
        }
        return this.inputHistory[this.historyIndex];
      },
      historyNavigatePrev: function() {
        this.historyIndex--;
        if(this.historyIndex < 0) {
          this.historyIndex = 0;
        }
        return this.inputHistory[this.historyIndex];
      },
      historyNavigateClear: function() {
        this.historyIndex = this.inputHistory.length - 1;
      },
			setText: function(text) {
				formHint.val(text);
				formInput.val(text);
			},
			getText: function() {
				return formInput.val();
			},
			hideDropDown: function() {
				dropDownController.hide();
			},
			repaint: function() {
				var text = formInput.val();
				var startFrom = rs.startFrom;
				var options = rs.options;
				var optionsLength = options.length;

				var tokens = text.substring(startFrom).split(" ");
				var token = tokens[tokens.length - 1];
				leftSide = "";
				for (var i = 0; i < tokens.length - 1; ++i) {
					leftSide += tokens[i] + " ";
				}

				formHint.val('');
				for (var i = 0; i < optionsLength; i++) {
					var opt = options[i];
					if (opt.indexOf(token) === 0) {
						formHint.val(leftSide + opt);
						break;
					}
				}

				dropDown.css('left', calculateWidthForText(leftSide) + 'px');
				if (token == '') {
					dropDownController.refresh(token, []);
				} else {
					dropDownController.refresh(token, rs.options);
				}
			}
		};

		var registerOnTextChangeOldValue;
		var registerOnTextChange = function(txt, callback) {
			registerOnTextChangeOldValue = txt.val();
			var handler = function() {
				var value = txt.val();
				if (registerOnTextChangeOldValue !== value) {
					registerOnTextChangeOldValue = value;
					callback(value);
				}
			};
			txt.change(handler);
			txt.keyup(handler);
		};


		registerOnTextChange(formInput, function(text) {
			rs.onChange(text);
		});


		var keyDownHandler = function(e) {
			e = e || window.event;
			var keyCode = e.keyCode;

      if(formInput.val() == "") {
        rs.historyBrowsingActive = true;
      }

			if (keyCode == 33) {
				return;
			} // page up
			else if (keyCode == 34) {
				return;
			} // page down
      else if (keyCode == 27) { //escape
				dropDownController.hide();
				formHint.val(formInput.val());
				formInput.focus();
				return;
			} else if (keyCode == 39 || keyCode == 35 || keyCode == 9) {
				if (keyCode == 9) {
					e.preventDefault();
					e.stopPropagation();
					if (formHint.val().length == 0) {
						rs.onTab();
					}
				}
				if (formHint.val().length > 0) {
					dropDownController.hide();
					formInput.val(formHint.val());
					var hasTextChanged = registerOnTextChangeOldValue != formInput.val()
					registerOnTextChangeOldValue = formInput.val();
					if (hasTextChanged) {
						rs.onChange(formInput.val());
					}
				}
				return;
			} else if (keyCode == 13) { //enter
				if (formHint.val().length == 0) {
					rs.onEnter();
				} else {
					var wasDropDownHidden = (!dropDown.is(':visible'));
					dropDownController.hide();

					if (wasDropDownHidden) {
						formHint.val(formInput.val());
						formInput.focus();
						rs.onEnter();
						return;
					}

					formInput.val(formHint.val());
					var hasTextChanged = registerOnTextChangeOldValue != formInput.val()
					registerOnTextChangeOldValue = formInput.val();

					if (hasTextChanged) {
						rs.onChange(formInput.val());
					}

				}
				return;
			} else if (keyCode == 40) { // down
        if(settings.enableHistory && rs.historyBrowsingActive) {
          rs.onHistoryPrev();
        } else {
  				var m = dropDownController.move(+1);
  				if (m == '') {
  					rs.onArrowDown();
  				}
  				formHint.val(leftSide + m);
  				return;
        }
			} else if (keyCode == 38) { // up
        if(settings.enableHistory && rs.historyBrowsingActive) {
          rs.onHistoryNext();
        } else {
				  var m = dropDownController.move(-1);
				  if (m == '') {
			      rs.onArrowUp();
				  }
				  formHint.val(leftSide + m);
				}
        return;
			} else {
        rs.historyBrowsingActive = false;
        rs.historyNavigateClear();
      }
			formHint.val('');
		};

		formInput.keydown(keyDownHandler);

    container[0].__autocomplete__ = rs;
		return rs;
	}
});
