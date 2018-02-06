package com.react_native_signature;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;


import android.os.Environment;
import android.text.TextUtils;
import android.util.Pair;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;


import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.MeasureSpecAssertions;
import com.facebook.react.uimanager.events.RCTEventEmitter;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;

/**
 * Created by zoomyu on 17-1-12.
 */


public class RCTSigntureView extends ImageView implements View.OnTouchListener {

    public static final int STROKE = 0;
    public static final int ERASER = 1;
    public static final int DEFAULT_STROKE_SIZE = 7;
    public static final int DEFAULT_ERASER_SIZE = 50;

    private String watermarkString = "";
    private int lineSpacing = 20;
    private int wordSpacing = 50;
    private int watermarkAngle = 0;
    private int watermarkSize = 50;
    private int watermarkColor = Color.GRAY;
    private int signatureColor = Color.BLACK;

    private float strokeSize = DEFAULT_STROKE_SIZE;
    private float eraserSize = DEFAULT_ERASER_SIZE;

    private Path m_Path;
    private Paint m_Paint;
    private float mX, mY;

    private ArrayList<Pair<Path, Paint>> paths = new ArrayList<>();
    private ArrayList<Pair<Path, Paint>> undonePaths = new ArrayList<>();

    private Bitmap bitmap;
    private int mode = STROKE;

    public RCTSigntureView(Context context) {
        super(context);
        setFocusable(true);
        setFocusableInTouchMode(true);
        setBackgroundColor(Color.WHITE);
        this.setOnTouchListener(this);
        m_Paint = new Paint();
        m_Paint.setAntiAlias(true);
        m_Paint.setDither(true);
        m_Paint.setColor(signatureColor);
        m_Paint.setStyle(Paint.Style.STROKE);
        m_Paint.setStrokeJoin(Paint.Join.ROUND);
        m_Paint.setStrokeCap(Paint.Cap.ROUND);
        m_Paint.setStrokeWidth(strokeSize);

        m_Path = new Path();

        setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT));
        invalidate();
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        MeasureSpecAssertions.assertExplicitMeasureSpec(widthMeasureSpec, heightMeasureSpec);
        int width = MeasureSpec.getSize(widthMeasureSpec);
        int height = MeasureSpec.getSize(heightMeasureSpec);

        if (!TextUtils.isEmpty(watermarkString)) {
            float fontPixels = watermarkSize * getResources().getDisplayMetrics().scaledDensity;
            int linePixels = (int) (lineSpacing * getResources().getDisplayMetrics().scaledDensity);
            int wordPixels = (int) (wordSpacing * getResources().getDisplayMetrics().scaledDensity);
            this.setBackground(new WatermarkDrawable(width, height, watermarkString, linePixels,
                    wordPixels, watermarkAngle, fontPixels, watermarkColor));
        }

        setMeasuredDimension(width, height);
    }

    @Override
    public boolean onTouch(View v, MotionEvent event) {
        float x = event.getX();
        float y = event.getY();

        switch (event.getAction()) {
            case MotionEvent.ACTION_DOWN:
                touchStart(x, y);
                invalidate();
                break;
            case MotionEvent.ACTION_MOVE:
                touchMove(x, y);
                invalidate();
                break;
            case MotionEvent.ACTION_UP:
                touchUp();
                invalidate();
                break;
            default:
                break;
        }
        return true;
    }

    @Override
    protected void onDraw(Canvas canvas) {
        if (bitmap != null) {
            canvas.drawBitmap(bitmap, 0, 0, null);
        }

        for (Pair<Path, Paint> p : paths) {
            canvas.drawPath(p.first, p.second);
        }

    }

    private void touchStart(float x, float y) {
        undonePaths.clear();

        if (mode == ERASER) {
            m_Paint.setColor(Color.WHITE);
            m_Paint.setStrokeWidth(eraserSize);
        } else {
            m_Paint.setColor(signatureColor);
            m_Paint.setStrokeWidth(strokeSize);
        }

        Paint newPaint = new Paint(m_Paint);

        if (!(paths.size() == 0 && mode ==ERASER && bitmap == null)) {
            paths.add(new Pair<>(m_Path, newPaint));
        }

        m_Path.reset();
        m_Path.moveTo(x, y);
        mX = x;
        mY = y;
    }

    private void touchMove(float x, float y) {
        //TODO 稍后根据dx和dy计算笔画粗细
//        float dx = Math.abs(x - mX);
//        float dy = Math.abs(y - mY);
        m_Path.quadTo(mX, mY, (x + mX)/2, (y + mY)/2);
        mX = x;
        mY = y;
    }

    private void touchUp() {
        m_Path.lineTo(mX, mY);
        Paint newPaint = new Paint(m_Paint);

        if (!(paths.size() == 0 && mode == ERASER && bitmap == null)) {
            paths.add(new Pair<>(m_Path, newPaint));
        }

        m_Path = new Path();
    }

    public Bitmap getBitmap() {
        if (paths.size() == 0) {
            return null;
        }

        if (bitmap == null) {
            bitmap = Bitmap.createBitmap(this.getWidth(), this.getHeight(),
                    Bitmap.Config.ARGB_8888);
        }

        Canvas canvas = new Canvas(bitmap);

        for (Pair<Path, Paint> p : paths) {
            canvas.drawPath(p.first, p.second);
        }
        return  bitmap;
    }

    public Bitmap getSignature() {
        Bitmap signatureBitmap = Bitmap.createBitmap(this.getWidth(), this.getHeight(),
                Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(signatureBitmap);
        this.draw(canvas);
        return signatureBitmap;
    }

    public void erase() {
        paths.clear();
        undonePaths.clear();
        // 先判断是否已经回收
        if(bitmap != null && !bitmap.isRecycled()){
            // 回收并且置为null
            bitmap.recycle();
            bitmap = null;
        }
        System.gc();
        invalidate();
    }

    public void resetSignature() {
        erase();
    }

    public void saveSignature() {
        String savePath = Environment.getExternalStorageDirectory().toString();
        File saveDir = new File(savePath + "/signature");
        if (!saveDir.exists()) {
            saveDir.mkdirs();
        }
        String fileName = "signature_" + System.currentTimeMillis() + ".png";
        File file = new File(saveDir, fileName);
        if (file.exists()) {
            file.delete();
        }

        try {
            FileOutputStream out = new FileOutputStream(file);
            getSignature().compress(Bitmap.CompressFormat.PNG, 90, out);
//            getBitmap().compress(Bitmap.CompressFormat.PNG, 90, out);
            out.flush();
            out.close();
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }

        WritableMap resultMap = Arguments.createMap();
        resultMap.putString("savePath", file.getAbsolutePath());
        ReactContext reactContext = (ReactContext) getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), "topChange",
                resultMap);
    }

    public void setWatermarkString(String watermarkString) {
        this.watermarkString = watermarkString;
    }

    public void setLineSpacing(Integer lineSpacing) {
        this.lineSpacing = lineSpacing;
    }

    public void setWordSpacing(Integer wordSpacing) {
        this.wordSpacing = wordSpacing;
    }

    public void setWatermarkAngle(Integer watermarkAngle) {
        this.watermarkAngle = watermarkAngle;
    }

    public void setWatermarkSize(Integer watermarkSize) {
        this.watermarkSize = watermarkSize;
    }

    public void setWatermarkColor(Integer watermarkColor) {
        this.watermarkColor = watermarkColor;
    }

    public void setSignatureColor(Integer signatureColor) {
        this.signatureColor = signatureColor;
    }
}
