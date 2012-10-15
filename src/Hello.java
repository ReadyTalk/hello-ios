import java.io.InputStream;
import java.util.Properties;

public class Hello {
  private long peer;
  private final String message;

  public Hello(long peer) throws Exception {
    this.peer = peer;

    InputStream in = getClass().getResourceAsStream("/hello.properties");
    try {
      Properties props = new Properties();
      props.load(in);
      message = props.getProperty("message");
    } finally {
      in.close();
    }
  }

  public void draw(int x, int y, int width, int height) {
    drawText(peer, message, 10, 20, 24.0);
  }

  private static native void drawText(long peer, String text, int x, int y,
                                      double size);

  public void dispose() {
    peer = 0;
  }
}
