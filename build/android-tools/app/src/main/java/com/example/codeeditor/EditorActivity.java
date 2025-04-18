package com.example.codeeditor;

import android.app.Activity;
import android.os.Bundle;
import android.widget.EditText;

public class EditorActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EditText editText = new EditText(this);
        editText.setHint("Write your code here");
        setContentView(editText);
    }
}
