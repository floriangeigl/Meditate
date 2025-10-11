using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

class TwoColumnPickerView extends Ui.View {
    private var mTitle;
    private var mIsHourMinute; // true => H:MM, false => MM:SS
    private var mLeftMin, mLeftMax, mLeftPad, mLeftSuffix;
    private var mRightMin, mRightMax, mRightPad, mRightSuffix;
    private var mLeftValue, mRightValue; // current values (numbers)
    private var mSelectedCol; // 0 left, 1 right
    private var backgroundColor, foregroundColor;
    private var mSelectedTextColor, mUnselectedTextColor;
    private var width, height;

    function initialize(options) {
        View.initialize();
        mTitle = options[:title];
        mIsHourMinute = options[:isHourMinute];
        mLeftMin = options[:leftMin];
        mLeftMax = options[:leftMax];
        mLeftPad = options[:leftPad];
        mLeftSuffix = options[:leftSuffix];
        mRightMin = options[:rightMin];
        mRightMax = options[:rightMax];
        mRightPad = options[:rightPad];
        mRightSuffix = options[:rightSuffix];
        mLeftValue = options[:leftValue];
        mRightValue = options[:rightValue];
        mSelectedCol = 0;

        var colorTheme = GlobalSettings.loadColorTheme();
        if (colorTheme == ColorTheme.Dark) {
            backgroundColor = Gfx.COLOR_BLACK;
            foregroundColor = Gfx.COLOR_WHITE;
            mSelectedTextColor = Gfx.COLOR_WHITE;
            mUnselectedTextColor = Gfx.COLOR_LT_GRAY;
        } else {
            backgroundColor = Gfx.COLOR_WHITE;
            foregroundColor = Gfx.COLOR_BLACK;
            mSelectedTextColor = Gfx.COLOR_BLACK;
            mUnselectedTextColor = Gfx.COLOR_DK_GRAY;
        }
    }

    function setSelectedColumn(col) {
        if (col < 0) { 
            col = 0; 
        }
        if (col > 1) { 
            col = 1; 
        }
        mSelectedCol = col;
        Ui.requestUpdate();
    }

    function incrementSelected(delta) {
        if (mSelectedCol == 0) {
            mLeftValue += delta;
            if (mLeftValue > mLeftMax) { mLeftValue = mLeftMin; }
            if (mLeftValue < mLeftMin) { mLeftValue = mLeftMax; }
        } else {
            mRightValue += delta;
            if (mRightValue > mRightMax) { mRightValue = mRightMin; }
            if (mRightValue < mRightMin) { mRightValue = mRightMax; }
        }
        Ui.requestUpdate();
    }

    function getValues() {
        return [ mLeftValue, mRightValue ];
    }

    function getSelectedColumn() {
        return mSelectedCol;
    }

    function onLayout(dc) {
        View.onLayout(dc);
        width = dc.getWidth();
        height = dc.getHeight();
    }

    function onUpdate(dc) {
        View.onUpdate(dc);
        dc.setColor(Gfx.COLOR_TRANSPARENT, backgroundColor);
        dc.clear();
        dc.setColor(foregroundColor, Gfx.COLOR_TRANSPARENT);

        // Title
        var titleStr = (mTitle == null) ? "" : mTitle;
        dc.drawText(width/2, height*0.12, Gfx.FONT_SYSTEM_MEDIUM, titleStr, Gfx.TEXT_JUSTIFY_CENTER);

        // Layout columns
        var colWidth = width * 0.42; // leave some space for ':'
        var leftX = width * 0.27;
        var rightX = width * 0.73;
        var centerY = height * 0.55;

        // Separator ':'
        dc.drawText(width/2, centerY, Gfx.FONT_SYSTEM_MEDIUM, ":", Gfx.TEXT_JUSTIFY_CENTER);

        // Values
        var leftText = padValue(mLeftValue, mLeftPad) + (mLeftSuffix == null ? "" : mLeftSuffix);
        var rightText = padValue(mRightValue, mRightPad) + (mRightSuffix == null ? "" : mRightSuffix);

        // Left value (selected brighter)
        var leftColor = (mSelectedCol == 0) ? mSelectedTextColor : mUnselectedTextColor;
        dc.setColor(leftColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(leftX, centerY, Gfx.FONT_LARGE, leftText, Gfx.TEXT_JUSTIFY_CENTER);

        // Right value (selected brighter)
        var rightColor = (mSelectedCol == 1) ? mSelectedTextColor : mUnselectedTextColor;
        dc.setColor(rightColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(rightX, centerY, Gfx.FONT_LARGE, rightText, Gfx.TEXT_JUSTIFY_CENTER);
    }

    function padValue(val, pad) {
        var t = val + "";
        if (pad != null) {
            while (t.length() < pad) { 
                t = "0" + t; 
            }
        }
        return t;
    }
}

class TwoColumnPickerDelegate extends Ui.BehaviorDelegate {
    private var mView;
    private var mOnAccept;
    private var mIsHourMinute;

    function initialize(view, onAccept, isHourMinute) {
        BehaviorDelegate.initialize();
        mView = view;
        mOnAccept = onAccept;
        mIsHourMinute = isHourMinute;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        if (key == Ui.KEY_LEFT) {
            mView.setSelectedColumn(0);
            return true;
        } else if (key == Ui.KEY_RIGHT) {
            mView.setSelectedColumn(1);
            return true;
        } else if (key == Ui.KEY_UP) {
            mView.incrementSelected(+1);
            return true;
        } else if (key == Ui.KEY_DOWN) {
            mView.incrementSelected(-1);
            return true;
        } else if (key == Ui.KEY_ENTER) {
            // If currently on left, move to right; if on right, accept
            // We need selected column; add a simple heuristic using a toggle
            // Simpler: try switching; if already right, accept
            // Provide explicit getter in view for clarity
            if (mView.getValues() != null) { /* no-op: values used only to ensure view exists */ }
            if (mView != null && mView.getSelectedColumn() == 0) {
                mView.setSelectedColumn(1);
                return true;
            }
            var vals = mView.getValues();
            var totalSeconds;
            if (mIsHourMinute) {
                var totalMinutes = vals[0] * 60 + vals[1];
                totalSeconds = totalMinutes * 60;
            } else {
                totalSeconds = vals[0] * 60 + vals[1];
            }
            if (mOnAccept != null) {
                mOnAccept.invoke(totalSeconds);
            }
            Ui.popView(Ui.SLIDE_IMMEDIATE);
            return true;
        }
        return false;
    }
}
