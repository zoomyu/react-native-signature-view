'use strict'

import React, {Component} from 'react';
import PropTypes from 'prop-types';
import {
  findNodeHandle,
  requireNativeComponent,
  UIManager,
  View,
  processColor,
  DeviceEventEmitter
} from 'react-native';

var RCTSignatureView = requireNativeComponent('RCTSignatureView',
  {
    propTypes: {
      ...View.propTypes, // 包含默认的View的属性
      watermarkString: PropTypes.string,
      watermarkLineSpacing: PropTypes.number,
      watermarkWordSpacing: PropTypes.number,
      watermarkAngle: PropTypes.number,
      watermarkSize: PropTypes.number,
      watermarkColor: PropTypes.number,
      signatureColor: PropTypes.number,
    },
  }, {
    nativeOnly: {onChange: true}
});

class SignatureView extends React.Component {
  constructor() {
    super();
    this.subscription;
  }

  static propTypes = {
    watermarkColor: PropTypes.string, // 这里传过来的是string
    signatureColor: PropTypes.string,
    ...View.propTypes // 包含默认的View的属性
  }

  render() {
    return (
      <RCTSignatureView
        {...this.props}
        onChange={this._onChange.bind(this)}
        watermarkColor={processColor(this.props.watermarkColor)}
        signatureColor={processColor(this.props.signatureColor)}/>
    );
  }

  componentDidMount() {
    if (this.props.onSaveEvent) {
      this.subscription = DeviceEventEmitter.addListener(
        'onSaveEvent',
        this.props.onSaveEvent);
    }
  }

  componentWillUnmount() {
    if (this.subscription) {
      this.subscription.remove()
      this.subscription = null;
    }
  }

  _onChange(event) {
    if(event.nativeEvent.savePath){
      if (!this.props.onSaveEvent) {
        return;
      }
      this.props.onSaveEvent({
        savePath: event.nativeEvent.savePath
      });
    }
  }

  _resetSignature() {
    UIManager.dispatchViewManagerCommand(
        findNodeHandle(this),
        UIManager.RCTSignatureView.Commands.resetSignature,
        [],
    );
  }

  _saveSignature() {
    UIManager.dispatchViewManagerCommand(
      findNodeHandle(this),
      UIManager.RCTSignatureView.Commands.saveSignature,
      [],
    );
  }
}

module.exports = SignatureView;
