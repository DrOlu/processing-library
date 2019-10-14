// Copyright (C) 2019 RunwayML Examples
// 
// This file is part of RunwayML Examples.
// 
// Runway-Examples is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// Runway-Examples is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with RunwayML.  If not, see <http://www.gnu.org/licenses/>.
// 
// ===========================================================================

// RUNWAYML
// www.runwayml.com

// Face Recognition Identify Demo:
// Receive HTTP messages from Runway
// Running Face-Recognition model

// import video library
import processing.video.*;
// import Runway library
import com.runwayml.*;
// reference to runway instance
RunwayHTTP runway;

// The data coming in from Runway as a JSON Object {}
JSONObject data;

// reference to the camera
Capture camera;

// periocally to be updated using millis()
int lastMillis;
// how often should the above be updated and a time action take place ?
int waitTime = 1000;

PImage labelImage;

void setup() {
  size(1200, 400);
  frameRate(3);
  fill(255);
  stroke(255);
  // setup Runway
  runway = new RunwayHTTP(this);
  // disable automatic polling: request data manually when a new frame is ready
  runway.setAutoUpdate(false);
  // setup camera
  camera = new Capture(this,640,480);
  camera.start();
  // setup timer
  lastMillis = millis();
}

void draw() {
  // update timer
  int currentMillis = millis();
  // if the difference between current millis and last time we checked past the wait time
  if(currentMillis - lastMillis >= waitTime){
    // call the timed function
    sendFrameToRunway();
    // update lastMillis, preparing for another wait
    lastMillis = currentMillis;
  }
  background(0);
  // draw input image (if any)
  if(labelImage != null){
    image(labelImage,600,0);
  }
  // draw webcam image
  image(camera,0,0);
  
  // Display captions
  drawCaptions();
  
  // Display instructions
  text("press SPACE to select an input image",5,15);
}

void keyPressed(){
  if(key == ' '){
    selectInput("Select a file to process:", "fileSelected");
  }
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("selected " + selection.getAbsolutePath());
    labelImage = loadImage(selection.getAbsolutePath());
    // resize image to 600x400
    labelImage.resize(600,400);
  }
}

// A function to display the captions
void drawCaptions() {
  // if no data is loaded yet, exit
  if(data == null){
    return;
  }
  println(data);
  // access boxes and labels JSON arrays within the result
  JSONArray results = data.getJSONArray("results");
  // for each array element
  for(int i = 0 ; i < results.size(); i++){
    JSONObject result = results.getJSONObject(i);
    
    String className = result.getString("class");
    JSONArray box = result.getJSONArray("bbox");
    // extract values from the float array
    float x = box.getFloat(0);
    float y = box.getFloat(1);
    float w = box.getFloat(2);
    float h = box.getFloat(3);
    // display bounding boxes
    noFill();
    rect(x,y,w,h);
    fill(255);
    text(className,x,y);
  }
}

void sendFrameToRunway(){
  // if there's no label image, don't send anything
  if(labelImage == null){
    return;
  }
  // nothing to send if there's no new camera data available
  if(camera.available() == false){
    return;
  }
  // read a new frame
  camera.read();
  // crop image to Runway input format (600x400)
  PImage inputImage = camera.get(0,0,600,400);
  // prepare input JSON object
  JSONObject input = new JSONObject();
  input.setString("input_image",ModelUtils.toBase64(inputImage));
  input.setString("label_image",ModelUtils.toBase64(labelImage));
  // request 75% match
  input.setFloat("match_tolerance",0.75);
  // query Runway with webcam image and input image
  runway.query(input.toString());
}

// this is called when new Runway data is available
void runwayDataEvent(JSONObject runwayData){
  // point the sketch data to the Runway incoming data 
  data = runwayData;
}
