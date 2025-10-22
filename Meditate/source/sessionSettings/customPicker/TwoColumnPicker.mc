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
        // Initialize current values with provided options or fall back to min bounds
        var _lv = options[:leftValue];
        var _rv = options[:rightValue];
        mLeftValue = (_lv == null) ? mLeftMin : _lv;
        mRightValue = (_rv == null) ? mRightMin : _rv;
        // Clamp to valid ranges to avoid out-of-bounds
        if (mLeftValue < mLeftMin) { mLeftValue = mLeftMin; }
        if (mLeftValue > mLeftMax) { mLeftValue = mLeftMax; }
        if (mRightValue < mRightMin) { mRightValue = mRightMin; }
        if (mRightValue > mRightMax) { mRightValue = mRightMax; }
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
            return _advanceOrAccept();
        }
        return false;
    }

    // Unified swipe handling for up/down (value change) and left/right (column selection).
    function onSwipe(swipeEvent) {
        var dir = swipeEvent.getDirection();
        if (dir == Ui.SWIPE_UP) {
            mView.incrementSelected(+1);
            return true;
        } else if (dir == Ui.SWIPE_DOWN) {
            mView.incrementSelected(-1);
            return true;
        } else if (dir == Ui.SWIPE_LEFT) {
            mView.setSelectedColumn(0);
            return true;
        } else if (dir == Ui.SWIPE_RIGHT) {
            mView.setSelectedColumn(1);
            return true;
        }
        return false;
    }

    // Tap should mimic ENTER key behavior.
    function onTap(tapEvent) {
        // We ignore tap location since columns are visually distinct; simple logic suffices.
        return _advanceOrAccept();
    }

    // Shared logic for advancing selection or accepting values.
    function _advanceOrAccept() {
        if (mView.getSelectedColumn() == 0) {
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
}
