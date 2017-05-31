
import React, { Component } from 'react';
import {
  StyleSheet,
  TouchableOpacity,
  Text,
  View
} from 'react-native';

import SignatureView from 'react-native-signature-view';

export default class Root extends Component {
  constructor(props) {
    super(props);
    this.state = {
      watermarkString: 'ORDER--12345678',
      watermarkSize: 14,
      watermarkColor: '#888888',
      signatureColor: '#000000',
      watermarkLineSpacing: 20,
      watermarkWordSpacing: 10,
      watermarkAngle: 45,
    };
  }

  render() {
    return (
      <View style={styles.container}>
          <SignatureView
            ref={'sign'}
            style={styles.signatureView}
            watermarkString={this.state.watermarkString}
            watermarkSize={this.state.watermarkSize}
            watermarkColor={this.state.watermarkColor}
            signatureColor={this.state.signatureColor}
            watermarkLineSpacing={this.state.watermarkLineSpacing}
            watermarkWordSpacing={this.state.watermarkWordSpacing}
            watermarkAngle={this.state.watermarkAngle}
            onSaveEvent={(msg)=>{
              console.log('onSaveEvent --->>', msg);
            }}
          />

          <View style={styles.buttonTab}>
            <TouchableOpacity style={styles.button} onPress={this._resetSign.bind(this)}>
              <Text>Redrawed</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.button} onPress={this._saveSign.bind(this)}>
              <Text>Save</Text>
            </TouchableOpacity>
          </View>
        </View>
    );
  }

  _resetSign() {
    this.refs["sign"]._resetSignature();
  }

  _saveSign(){
    this.refs["sign"]._saveSignature();
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5FCFF'
  },
  signatureView: {
    flex:1
  },
  buttonTab: {
    height: 48,
    flexDirection: 'row'
  },
  button: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center'
  }
});
