/**
 * Created by psindurakar on 11/23/2017.
 */
const webpack = require('webpack');
const { resolve } = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');

const CompressionPlugin = require('compression-webpack-plugin');

let BundleAnalyzerPlugin = require('webpack-bundle-analyzer')
  .BundleAnalyzerPlugin;
let WebpackBundleSizeAnalyzerPlugin = require('webpack-bundle-size-analyzer')
  .WebpackBundleSizeAnalyzerPlugin;

const ExtractTextPlugin = require('extract-text-webpack-plugin');

const MomentLocalesPlugin = require('moment-locales-webpack-plugin');
var SimpleProgressPlugin = require('webpack-simple-progress-plugin');

let inProduction = process.env.NODE_ENV === 'production';

let OptimizeCssAssetsPlugin = require('optimize-css-assets-webpack-plugin');

module.exports = {
  entry: [resolve(__dirname, 'src', 'index.production.js')],
  output: {
    filename: 'bundle.js',
    path: resolve(__dirname, 'dist')
  },
  stats: 'errors-only',
  devtool: 'source-map',
  resolve: {
    extensions: ['.js', '.jsx', '.json']
  },
  module: {
    rules: [
      {
        // js loading
        test: /\.jsx?$/,
        exclude: /node_modules\/(?!(auto-bind)\/).*/,
        loader: 'babel-loader',
        options: {
          babelrc: false,
          presets: [['es2015', { modules: false }], 'react', 'stage-2']
        }
      },
      {
        test: /\.(scss|css)$/,
        use: ExtractTextPlugin.extract({
          fallback: 'style-loader',
<<<<<<< .mine
          use: [
             {
                 loader: 'css-loader',
                 options: {
                     // If you are having trouble with urls not resolving add this setting.
                     // See https://github.com/webpack-contrib/css-loader#url
                     url: false,
                     minimize: true,
                     sourceMap: true
                 }
             },
             {
                 loader: 'sass-loader',
                 options: {
                     sourceMap: true
                 }
             }
           ]
=======
          use: 'css-loader?url=false'
>>>>>>> .r27946
        })
      },
      {
<<<<<<< .mine
=======
        test: /\.scss$/,
        use: ExtractTextPlugin.extract(['css-loader?url=false', 'sass-loader?sourceMap'])
      },
      {
>>>>>>> .r27946
        test: /\.(woff|woff2|ttf|eot|svg)(\?]?.*)?$/,
        loader: 'url-loader?name=res/[name].[ext]?[hash]'
      },
      {
        test: /\.(jpg|png)$/,
        loader: 'url-loader?limit=100000'
      }
    ]
  },
  plugins: [
    new webpack.LoaderOptionsPlugin({
      minimize: true,
      debug: false
    }),
    // using production environment
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: JSON.stringify('production')
      }
    }),

    new webpack.optimize.UglifyJsPlugin({ sourceMap: true  }),
    new HtmlWebpackPlugin({ title: 'PtoV', template: './src/index.html' }),
    new ExtractTextPlugin('style.css'),
    new OptimizeCssAssetsPlugin({
      cssProcessorOptions: {
        safe: true
      }
    }),
    new MomentLocalesPlugin({
      localesToKeep: ['en', 'en-gb']
    }),
    new WebpackBundleSizeAnalyzerPlugin('./plain-report.txt'),
    new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/),
    new CompressionPlugin({
      asset: '[path].gz[query]',
      algorithm: 'gzip',
      test: /\.js$|\.css$|\.html$/,
      threshold: 10240,
      minRatio: 0.8
    })
    , new BundleAnalyzerPlugin()
    , new SimpleProgressPlugin()
  ]
};
