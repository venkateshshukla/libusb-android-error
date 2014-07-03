package org.venky;

import android.app.Activity;
import android.os.Bundle;
import android.graphics.Color;

public class Home extends Activity
{
	public native int openUsbDevice();
	@Override
	public void onCreate(Bundle savedInstanceState)
	{
		int i;
		super.onCreate(savedInstanceState);
		setContentView(R.layout.main);
		i = openUsbDevice();
		if (i == 0) {
			getWindow().getDecorView().setBackgroundColor(Color.GREEN);
		} else {
			getWindow().getDecorView().setBackgroundColor(Color.RED);
		}
	}

	static {
		System.loadLibrary("venky");
	}
}
