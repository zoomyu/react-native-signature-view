package com.react_native_signature;

import android.support.annotation.Nullable;

import com.facebook.infer.annotation.Assertions;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;

import java.util.Map;


/**
 * Created by zoomyu on 17-1-13.
 */

public class RCTSignatureManager extends SimpleViewManager<RCTSigntureView> {
    public static final String REACT_CLASS = "RCTSignatureView";

    public static final int COMMAND_SAVE_SIGNATURE = 0x01;
    public static final int COMMAND_RESET_SIGNATURE = 0x02;

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @Override
    protected RCTSigntureView createViewInstance(ThemedReactContext reactContext) {
        return new RCTSigntureView(reactContext);
    }

    @ReactProp(name = "watermarkString")
    public void setWatermarkString(RCTSigntureView view, @Nullable String watermarkString) {
        view.setWatermarkString(watermarkString);
    }

    @ReactProp(name = "watermarkLineSpacing")
    public void setLineSpacing(RCTSigntureView view, @Nullable Integer lineSpacing) {
        view.setLineSpacing(lineSpacing);
    }

    @ReactProp(name = "watermarkWordSpacing")
    public void setWordSpacing(RCTSigntureView view, @Nullable Integer wordSpacing) {
        view.setWordSpacing(wordSpacing);
    }

    @ReactProp(name = "watermarkAngle")
    public void setWatermarkAngle(RCTSigntureView view, @Nullable Integer tiltAngle) {
        view.setWatermarkAngle(tiltAngle);
    }

    @ReactProp(name = "watermarkSize")
    public void setWatermarkSize(RCTSigntureView view, @Nullable Integer watermarkSize) {
        view.setWatermarkSize(watermarkSize);
    }

    @ReactProp(name = "watermarkColor")
    public void setWatermarkColor(RCTSigntureView view, @Nullable Integer watermarkColor) {
        view.setWatermarkColor(watermarkColor);
    }

    @ReactProp(name = "signatureColor")
    public void setSignatureColor(RCTSigntureView view, @Nullable Integer signatureColor) {
        view.setSignatureColor(signatureColor);
    }

    @javax.annotation.Nullable
    @Override
    public Map<String, Integer> getCommandsMap() {
        return MapBuilder.of(
                "saveSignature", COMMAND_SAVE_SIGNATURE,
                "resetSignature", COMMAND_RESET_SIGNATURE);
    }

    @Override
    public void receiveCommand(RCTSigntureView root, int commandId,
                               @javax.annotation.Nullable ReadableArray args) {
        super.receiveCommand(root, commandId, args);
        Assertions.assertNotNull(root);
        Assertions.assertNotNull(args);
        switch (commandId) {
            case COMMAND_SAVE_SIGNATURE: {
                root.saveSignature();
                break;
            }
            case COMMAND_RESET_SIGNATURE: {
                root.resetSignature();
                break;
            }

            default:
                throw new IllegalArgumentException(String.format(
                        "Unsupported command %d received by %s.",
                        commandId,
                        getClass().getSimpleName()));
        }
    }
}
