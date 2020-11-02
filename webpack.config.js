const path = require('path');

module.exports = {
  entry: './root/static/js/canto-modules.js',
  output: {
    filename: 'main.js',
    path: path.resolve(__dirname, 'root/dist'),
  },
  mode: 'development'
};