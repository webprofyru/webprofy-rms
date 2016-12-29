(function (realWindow) {
    "use strict";

    var window = {};

    window.__proto__ = realWindow;

    window.addEventListener = function (arg1, arg2, arg3) {
        realWindow.addEventListener(arg1, arg2, arg3);
    };

    window.setImmediate = function (arg1) {
        realWindow.setImmediate(arg1);
    };

    window.postMessage = function (arg1, arg2) {
        realWindow.postMessage(arg1, arg2);
    };

    (function(window) {

        //=include ../node_modules/requirejs/require.js

        //=include ../fixed/excel-builder/excel-builder.compiled.js

        require(['excel-builder'], function (ExcelBuilder) {
            realWindow.ExcelBuilder = ExcelBuilder
        });

    }).call(window, window);

})(window)