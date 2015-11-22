/*
 * Copyright (c) 2015, Seraphim Sense Ltd.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions
 *    and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of
 *    conditions and the following disclaimer in the documentation and/or other materials provided
 *    with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to
 *    endorse or promote products derived from this software without specific prior written
 *    permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
 * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
package com.angel.sample_app;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.view.View;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Queue;
import java.util.concurrent.ConcurrentLinkedQueue;

public class GraphView extends View {
    public static final float BEZIER_FINE_FIT = 0.5f;

    private int maximumNumberOfValues = 400;
    private int strokeColor = 0xff78c247;
    private int strokeWidth = 1; // dp

    private RectF drawingArea;
    private Paint paint;
    private Queue<Float> valuesCache;
    private List<Float> previousValuesCache;
    private List<Float> currentValuesCache;

    private float scaleInX = 0f;
    private float scaleInY = 0f;
    private float minValue = 0f;
    private float maxValue = 1f;

        public GraphView(Context context) {
        super(context);
        initView();
    }

    public GraphView(Context context, AttributeSet attrs) {
        super(context, attrs);
        initView();
    }

    public GraphView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView();
    }

    private void initView() {
        initPaint();
        initCaches();
    }

    private void initPaint() {
        paint = new Paint();
        paint.setFlags(Paint.ANTI_ALIAS_FLAG);
        paint.setColor(strokeColor);
        paint.setStyle(Paint.Style.STROKE);
        paint.setStrokeCap(Paint.Cap.ROUND);
        paint.setStrokeWidth(dpToPx(strokeWidth));
    }

    private void initCaches() {
        if (isInEditMode()) {
            initCacheForDesigner();
        } else {
            initCacheForRuntime();
        }
        previousValuesCache = cloneCache();
        currentValuesCache = cloneCache();
    }

    private void initCacheForDesigner() {
        maximumNumberOfValues = 50;
        valuesCache = new ConcurrentLinkedQueue<Float>();
        for (int i = 0; i < maximumNumberOfValues; i++) {
            if (i % 2 == 0) {
                valuesCache.add(minValue);
            } else {
                valuesCache.add(maxValue);
            }
        }
    }

    private void initCacheForRuntime() {
        valuesCache = new ConcurrentLinkedQueue<Float>();
        for (int counter = 0; counter < maximumNumberOfValues; counter++) {
            valuesCache.add(minValue);
        }
    }

    public void setMaximumNumberOfValues(int maximumNumberOfValues) {
        if (maximumNumberOfValues < 100) {
            throw new IllegalArgumentException("The maximum number of values cannot be less than 100.");
        }
        this.maximumNumberOfValues = maximumNumberOfValues;
        calculateScales();
        initCaches();
    }

    public void setStrokeColor(int strokeColor) {
        paint.setColor(strokeColor);
    }

    public void setStrokeWidth(int dp) {
        this.strokeWidth = dp;
    }

    public void addValue(float value) {

        if (value > maxValue) maxValue = value;
        if (value < minValue) minValue = value;

        previousValuesCache = cloneCache();
        if (valuesCache.size() == maximumNumberOfValues) {
            float pollValue = valuesCache.poll();

            if (pollValue == maxValue) maxValue = Collections.max(valuesCache);
            else if (pollValue == minValue) minValue = Collections.min(valuesCache);

        }
        valuesCache.add(value);
        currentValuesCache = cloneCache();
        calculateScales();
        invalidate();
    }

    public void clear() {
        initCaches();
        invalidate();
    }

    private List<Float> cloneCache() {
        return new ArrayList<Float>(valuesCache);
    }

    private float dpToPx(float value) {
        return TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value,
                getResources().getDisplayMetrics());
    }

    @Override
    protected void onSizeChanged(int width, int height, int oldWidth, int oldHeight) {
        calculateDrawingArea(width, height);
        calculateScales();
    }

    private void calculateDrawingArea(int width, int height) {
        int left = (strokeWidth * 2) + getPaddingLeft();
        int top = (strokeWidth * 2) + getPaddingTop();
        int right = width - getPaddingRight() - strokeWidth;
        int bottom = height - getPaddingBottom() - strokeWidth;
        drawingArea = new RectF(left, top, right, bottom);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        if (!valuesCache.isEmpty()) {
            Path path = buildPath();
            canvas.drawPath(path, paint);
        }
    }

    private Path buildPath() {
        Path path = new Path();
        float previousX = drawingArea.left;
        float previousY = drawingArea.bottom;
        for (int index = 0; index < currentValuesCache.size(); index++) {
            float previousValue = previousValuesCache.get(index);
            float currentValue = currentValuesCache.get(index);
            float pathValue = previousValue + (currentValue - previousValue);
            float x = drawingArea.left + (scaleInX * index);
            float y = drawingArea.bottom - ((pathValue - minValue) * scaleInY);
            if (index == 0) {
                path.moveTo(x, y);
            } else {
                float bezierControlX = previousX + ((x - previousX) * BEZIER_FINE_FIT);
                path.cubicTo(bezierControlX, previousY, bezierControlX, y, x, y);
            }
            previousX = x;
            previousY = y;
        }
        return path;
    }

    private void calculateScales() {
        if (drawingArea != null) {
            scaleInX = (drawingArea.width() / (maximumNumberOfValues - 1));
            scaleInY = (drawingArea.height() / (maxValue - minValue));
        } else {
            scaleInY = 0f;
            scaleInX = 0f;
        }
    }
}