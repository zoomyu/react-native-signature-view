package com.react_native_signature;

import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.ColorFilter;
import android.graphics.Paint;
import android.graphics.PixelFormat;
import android.graphics.drawable.Drawable;
import android.support.annotation.IntRange;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;

/**
 * Created by zoomyu on 17-1-17.
 */

public class WatermarkDrawable extends Drawable{
    private Paint mPaint;
    private String watermarkString;
    private int lineSpacing;
    private int wordSpacing;
    private int watermarkAngle;

    private int mWatermarkHeight;
    private int mWatermarkWidth;

    private int top;
    private int bottom;
    private int left;
    private int right;

    public WatermarkDrawable(int width, int height, String watermarkString, int lineSpacing,
                             int wordSpacing, int watermarkAngle, float watermarkSize,
                             int watermarkColor) {

        this.watermarkString = watermarkString;
        this.lineSpacing = lineSpacing;
        this.wordSpacing = wordSpacing;
        this.watermarkAngle = watermarkAngle;

        mPaint = new Paint();
        mPaint.setColor(watermarkColor);
        mPaint.setTextSize(watermarkSize);
        Paint.FontMetrics fontMetrics= mPaint.getFontMetrics();
        mWatermarkHeight = (int) (-fontMetrics.ascent+fontMetrics.descent); //水印字体高度
        mWatermarkWidth = (int) mPaint.measureText(watermarkString); //水印字体宽度
        watermarkAngle = watermarkAngle%360>=0 ?  watermarkAngle%360 : watermarkAngle%360+360;
        double radian = Math.PI*watermarkAngle/180;
        int dh = lineSpacing + mWatermarkHeight;
        int dw = wordSpacing + mWatermarkWidth;

        if (watermarkAngle > 270) {
            top = -dh;
            bottom = (int) (height*Math.cos(radian) - width*Math.sin(radian)) + dh;
            left = (int) (height*Math.sin(radian)) - dw;
            right = (int) (width*Math.cos(radian)) + dw;
        } else if (watermarkAngle > 180) {
            top = (int) (height*Math.cos(radian)) - dh;
            bottom = (int) (-width*Math.sin(radian)) + dh;
            left = (int) (height*Math.sin(radian) + width*Math.cos(radian)) - dw;
            right = dw;
        } else if (watermarkAngle > 90) {
            top = (int) (height*Math.cos(radian) - width*Math.sin(radian)) - dh;
            bottom = dh;
            left = (int) (width*Math.cos(radian)) - dw;
            right = (int) (height*Math.sin(radian)) + dw;
        } else if (watermarkAngle >= 0) {
            top = (int) (-width*Math.sin(radian)) - dh ;
            bottom = (int) (height*Math.cos(radian)) + dh ;
            left = -dw;
            right = (int) (height*Math.sin(radian) + width*Math.cos(radian)) + dw;
        }

    }

    @Override
    public void draw(@NonNull Canvas canvas) {
        canvas.drawColor(Color.WHITE);
        canvas.rotate(watermarkAngle);
        int temp = -(mWatermarkWidth + wordSpacing)/4;

        for (int h = top; h <= bottom; h = h + mWatermarkHeight + lineSpacing) {
            temp = -temp;
            for (int w = left; w <= right; w = w + mWatermarkWidth + wordSpacing) {
                canvas.drawText(watermarkString, w + temp, h, mPaint);
            }
        }

        canvas.rotate(-watermarkAngle);
    }

    @Override
    public void setAlpha(@IntRange(from = 0, to = 255) int alpha) {
        mPaint.setAlpha(alpha);
    }

    @Override
    public void setColorFilter(@Nullable ColorFilter colorFilter) {
        mPaint.setColorFilter(colorFilter);
    }

    @Override
    public int getOpacity() {
        return PixelFormat.TRANSPARENT;
    }
}
