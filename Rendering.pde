public class RenderThread extends Thread {

  public String translatex;
  public String translatey;
  public String rotation;
  public PGraphics render;
  public PGraphics motif;
  
  private float motifsize;
  private float mhs;
  private float[] rendersize;
  private float secured_percent;
  private float percent;
  private boolean finished;
  private int columns;
  private int rows;

  private ScriptEngineManager jsMgr;
  private ScriptEngine jsEngine;

  public RenderThread() {
    secured_percent = 1;
    percent = 1;
    finished = true;
    render = null;
    motif = null;
    rendersize = null;
    columns = 0;
    rows = 0;
    // creation of the javascript parser, used in RenderThread
    jsMgr = new ScriptEngineManager();
    jsEngine = jsMgr.getEngineByName("JavaScript");
  }

  public boolean isFinished() {
    boolean out = false;
    try {
      out = finished;
    } 
    catch( Exception e ) {
      out = false;
    }
    return out;
  }

  public float getPercent() {
    float pc = secured_percent;
    try {
      secured_percent = percent;
    } 
    catch( Exception e ) {
    }
    return pc;
  }
  
  public int getColumns() {
    if ( !isFinished() ) return 0;
    return columns;
  }
  
  public int getRows() {
    if ( !isFinished() ) return 0;
    return rows;
  }

  @Override
  public void start() {
    secured_percent = 0;
    percent = 0;
    columns = 0;
    rows = 0;
    finished = false;
    motifsize = motif.width;
    mhs = motifsize * 0.5;
    rendersize = new float[] { render.width, render.height };
    super.start();
    println( "starting thread" );
  }

  @Override
  public void run() {
    
    if ( render == null ) {
      percent = 1;
      finished = true;
      return;
    } else {
      loadJsFunctions();
      render.beginDraw();
      render.background( 0,0 );
      float px = 0;
      float py = 0;
      float xtotal = 0;
      float ytotal = 0;
      for ( int x = 0; xtotal < rendersize[ 0 ]; x++ ) {
        ytotal = 0;
        for ( int y = 0; ytotal < rendersize[ 1 ]; y++ ) {
          if ( x == 0 ) rows++;
          render.pushMatrix();
          px = jsTranslateX( x, y, motifsize );
          py = jsTranslateY( x, y, motifsize );
          ytotal = py;
          render.translate( px + mhs, py + mhs );
          render.rotate( jsRotate( x, y, motifsize ) );
          render.image( motif, -mhs, -mhs );
          render.popMatrix();
          yield();
        }
        xtotal = px;
        columns++;
        percent = ( xtotal / width );
      }
      render.endDraw();
      finished = true;
      println( "thread run finished" );
    }
  }

  private void loadJsFunctions() {
    String func = "function renderTX(x,y,s) { return " + translatex + "; }";
    func += "function renderTY(x,y,s) { return " + translatey + "; }";
    func += "function renderR(x,y,s) { return " + rotation + "; }";
    try {
      jsEngine.eval(func);
    } catch ( Exception e ) {
    }
  }

  private float jsTranslateX( float x, float y, float s ) {
    String func = "renderTX( " + x + ", " + y + ", " + s + " );";
    try {
      float v = Float.parseFloat( jsEngine.eval(func).toString() );
      return v;
    } catch ( Exception e ) {
      return 0;
    }
  }

  private float jsTranslateY( float x, float y, float s ) {
    String func = "renderTY( " + x + ", " + y + ", " + s + " );";
    try {
      float v = Float.parseFloat( jsEngine.eval(func).toString() );
      return v;
    } catch ( Exception e ) {
      return 0;
    }
  }

  private float jsRotate( float x, float y, float s ) {
    String func = "renderR( " + x + ", " + y + ", " + s + " );";
    try {
      return Float.parseFloat( jsEngine.eval(func).toString() ) / 180 * PI;
    } catch ( Exception e ) {
      return 0;
    }
  }
  
}