import javax.script.ScriptEngineManager;
import javax.script.ScriptEngine;
import javax.swing.JFileChooser;
import controlP5.*;

ControlP5 cp5;

PGraphics motif;
PGraphics render;

// motif size in slider
int size = 40;
// motif siwe used in calculations
int motifsize;
// half of the motif size
float msh;
// rendering thread, check tab "Rendering" if you need to modify the code
RenderThread rthread;
// string used to reopen the file dialog at the last position
String exportpath;
// string used to store the render info
String info;

int fgcolor = color( 255 );
int bgcolor = color( 200 );

void setup() {

  size( 880, 880 );

  // creation of the UI
  int tfsize = 150;
  int tfx = 10;
  int tfy = 10;
  PFont font = createFont("courier", 11);
  cp5 = new ControlP5(this);
  cp5.addSlider("size").setFont( font ).setPosition( tfx, tfy ).setSize( tfsize, 15 ).setRange( 5, 100 ); tfy += 20;
  cp5.addTextfield("translatex").setFont( font ).setValue( "x*s" ).setPosition( tfx, tfy ).setSize( tfsize, 15); tfx += tfsize + 10;
  cp5.addTextfield("translatey").setFont( font ).setValue( "y*s" ).setPosition( tfx, tfy ).setSize( tfsize, 15); tfx += tfsize + 10;
  cp5.addTextfield("rotation").setFont( font ).setValue( "0" ).setPosition( tfx, tfy ).setSize( tfsize, 15); tfx += tfsize + 10;
  // this button calls the method "apply()", defined here below
  cp5.addButton("apply").setFont( font ).setPosition( tfx, tfy ).setSize( 50, 15 ); tfx += 55;
  // this button calls the method "save()", defined here below
  cp5.addButton("save").setFont( font ).setPosition( tfx, tfy ).setSize( 50, 15 ); tfx = 10; tfy += 35;
  cp5.addTextlabel("label").setFont( font ).setText("available variables: x, y, s (= size)").setPosition( tfx - 5, tfy ); tfy += 15;
  cp5.addTextlabel("info").setFont( font ).setText("-").setColor( color( 0,255,255 ) ).setPosition( tfx - 5, tfy ); tfy += 20;
  // colors
  cp5.addColorWheel("fgcolor" , 710 , 5 , 80 ).setFont( font ).setRGB( color( 255 ) );
  cp5.addColorWheel("bgcolor" , 795 , 5 , 80 ).setFont( font ).setRGB( color( 200 ) );

  // creation of a texture to store rendering
  render = createGraphics( width, height );
  render.beginDraw();
  render.background( 0,0 );
  render.endDraw();
  
  // no thread by default
  rthread = null;
  
}

// modify this method to change the motif
// work with relative size if you want to use the size slider, controling the motif's size
void createMotif() {

  // motif with a cross and a square at 45°
  // creation of a texture for the motif
  // this texture will be repeated during rendering
  motif = createGraphics( motifsize, motifsize );
  motif.beginDraw();
  // transparent background
  motif.background( 0, 0 );
  motif.strokeWeight( 1 );
  motif.stroke( 0 );
  motif.pushMatrix();
  motif.translate( msh, msh );
  motif.line( 0, -motifsize, 0, motifsize );
  motif.line( -motifsize, 0, motifsize, 0 );
  motif.rotate( HALF_PI * 0.5 );
  motif.rect( -msh*0.3, -msh*0.3, msh*0.6, msh*0.6 );
  motif.popMatrix();
  motif.endDraw();
  
  // motif with quarter of a circle
  /*
  motif = createGraphics( motifsize, motifsize );
  motif.beginDraw();
  motif.background( 0, 0 );
  motif.noFill();
  motif.strokeWeight( 10 );
  motif.stroke( 127 );
  motif.ellipse( 0,0, motifsize * 2, motifsize * 2 ); 
  motif.strokeWeight( 2 );
  motif.stroke( 255 );
  motif.ellipse( 0,0, motifsize * 2, motifsize * 2 );  
  motif.endDraw();
  */
  
}

void apply() {
  
  // another process is still running!
  // wait for it to end to click on apply again
  if ( rthread != null ) return;
  
  // if the motif's size changed, generation of a new texture
  if ( size != motifsize ) {
    motifsize = size;
    msh = motifsize * 0.5;
    createMotif();
  }
  
  // creation of a new thread for rendering
  rthread = new RenderThread();
  // setting all paranmeters
  rthread.render = render;
  rthread.motif = motif;
  rthread.translatex = cp5.get(Textfield.class, "translatex").getText();
  rthread.translatey = cp5.get(Textfield.class, "translatey").getText();
  rthread.rotation = cp5.get(Textfield.class, "rotation").getText();
  // and eventually launching the thread
  rthread.start();
  
  cp5.get(Textlabel.class, "info").setText( "rendering started" );
  
}

void save() {
  
  // a rendering is running!
  // wait for it to end to click on save again
  if ( rthread != null ) return;
  
  JFileChooser fileChooser = new JFileChooser( exportpath );
  if (fileChooser.showSaveDialog(frame) == JFileChooser.APPROVE_OPTION) {
    File file = fileChooser.getSelectedFile();
    exportpath = file.getAbsolutePath();
    if ( exportpath.lastIndexOf( ".png" ) != exportpath.length() - 4 ) {
      exportpath += ".png";
    }
    render.save( exportpath );
  }
}

void draw() {

  background( bgcolor );
  
  // no thread is running, let's display the result
  if ( rthread == null ) {
    
    tint( fgcolor );
    image( render, 0, 0 );
    noTint();
    
  } else if ( rthread != null ) {
    
    // a thread is running! 
    // because it's far too dangerous to try to display the render while the thread works on it
    // we display a percentage bar, reprensenting the number of columns done / total width
    float pc = rthread.getPercent();
    pushMatrix();
    translate( width * 0.5 - 100, height * 0.5 - 5 );
    fill( 80 );
    stroke( 255 );
    rect( -1, -1, 202, 12 );
    noStroke();
    fill( 255,0,0 );
    rect( 0,0, 200 * pc, 10 );
    popMatrix();
    // once the thread as done its job, we trash it
    if ( rthread.isFinished() ) { 
      info = "grid: " + ( rthread.getColumns() - 1 ) + "x" + ( rthread.getRows() - 1 );
      cp5.get(Textlabel.class, "info").setText( info );
      rthread = null;
    }
  }
  
  noStroke();
  fill( 0, 180 );
  rect( 0, 0, width, 105 );
  
}