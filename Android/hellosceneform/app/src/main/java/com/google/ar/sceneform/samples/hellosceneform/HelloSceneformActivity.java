/*
 * Copyright 2018 Google LLC. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.google.ar.sceneform.samples.hellosceneform;

import android.app.Activity;
import android.app.ActivityManager;
import android.content.Context;
import android.os.Build;
import android.os.Build.VERSION_CODES;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.MotionEvent;
import android.view.ViewGroup;
import android.widget.Toast;

import com.google.android.gms.maps.MapView;
import com.google.ar.core.Anchor;
import com.google.ar.core.HitResult;
import com.google.ar.core.Plane;
import com.google.ar.sceneform.AnchorNode;
import com.google.ar.sceneform.rendering.ViewRenderable;
import com.google.ar.sceneform.ux.ArFragment;
import com.google.ar.sceneform.ux.TransformableNode;

import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.OnMapReadyCallback;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.MarkerOptions;

import java.util.concurrent.CompletableFuture;

/**
 * This is an example activity that uses the Sceneform UX package to make common AR tasks easier.
 */
public class HelloSceneformActivity extends AppCompatActivity implements OnMapReadyCallback {
    private static final String TAG = HelloSceneformActivity.class.getSimpleName();
    private static final double MIN_OPENGL_VERSION = 3.0;

    private ArFragment arFragment;
    private ViewRenderable mapRenderable;
    private float planeX, planeZ;

    private GoogleMap mMap;
    private boolean hasMap = false;

    @Override
    @SuppressWarnings({"AndroidApiChecker", "FutureReturnValueIgnored"})
    // CompletableFuture requires api level 24
    // FutureReturnValueIgnored is not valid
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        if (!checkIsSupportedDeviceOrFinish(this)) {
            return;
        }

        setContentView(R.layout.activity_ux);
        arFragment = (ArFragment) getSupportFragmentManager().findFragmentById(R.id.ux_fragment);

        // When you build a Renderable, Sceneform loads its resources in the background while returning
        // a CompletableFuture. Call thenAccept(), handle(), or check isDone() before calling get().
        ViewRenderable.builder()
                .setView(this, R.layout.activity_main)
                .build()
                .thenAccept(renderable -> {
                    mapRenderable = renderable;
//                    MapView mapView = (MapView) renderable.getView();
//                    ViewGroup.LayoutParams param = mapView.getLayoutParams();
//                    param.width = 500;
//                    param.height = 500;
//                    mapView.setLayoutParams(param);
//                    mapView.getMapAsync(new MapViewActivity());
                });

        arFragment.setOnTapArPlaneListener(
                (HitResult hitResult, Plane plane, MotionEvent motionEvent) -> {
                    if (hasMap) return;
                    hasMap = true;
                    this.planeX = plane.getExtentX();
                    this.planeZ = plane.getExtentZ();
                    // Create the Anchor.
                    Anchor anchor = hitResult.createAnchor();
                    AnchorNode anchorNode = new AnchorNode(anchor);
                    anchorNode.setParent(arFragment.getArSceneView().getScene());

                    // Create the transformable andy and add it to the anchor.
                    TransformableNode mapNode = new TransformableNode(arFragment.getTransformationSystem());
                    mapNode.setParent(anchorNode);
                    mapNode.setRenderable(mapRenderable);
                    mapNode.select();
                });
    }

    @Override
    public void onMapReady(GoogleMap googleMap) {
        mMap = googleMap;

        // Add a marker in Sydney and move the camera
        LatLng uva = new LatLng(38.0335788, -78.5099539);
        mMap.setMapType(GoogleMap.MAP_TYPE_SATELLITE);
        mMap.addMarker(new MarkerOptions().position(uva).title("here at UVA"));
        mMap.moveCamera(CameraUpdateFactory.newLatLng(uva));
    }

    /**
     * Returns false and displays an error message if Sceneform can not run, true if Sceneform can run
     * on this device.
     *
     * <p>Sceneform requires Android N on the device as well as OpenGL 3.0 capabilities.
     *
     * <p>Finishes the activity if Sceneform can not run
     */
    public static boolean checkIsSupportedDeviceOrFinish(final Activity activity) {
        if (Build.VERSION.SDK_INT < VERSION_CODES.N) {
            Log.e(TAG, "Sceneform requires Android N or later");
            Toast.makeText(activity, "Sceneform requires Android N or later", Toast.LENGTH_LONG).show();
            activity.finish();
            return false;
        }
        String openGlVersionString =
                ((ActivityManager) activity.getSystemService(Context.ACTIVITY_SERVICE))
                        .getDeviceConfigurationInfo()
                        .getGlEsVersion();
        if (Double.parseDouble(openGlVersionString) < MIN_OPENGL_VERSION) {
            Log.e(TAG, "Sceneform requires OpenGL ES 3.0 later");
            Toast.makeText(activity, "Sceneform requires OpenGL ES 3.0 or later", Toast.LENGTH_LONG)
                    .show();
            activity.finish();
            return false;
        }
        return true;
    }
}
