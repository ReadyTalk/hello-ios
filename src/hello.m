#include <jni.h>
#import <UIKit/UIKit.h>

#undef JNIEXPORT
#define JNIEXPORT __attribute__ ((visibility("default"))) \
  __attribute__ ((used))

JNIEXPORT void JNICALL
Java_Hello_drawText(JNIEnv* e, jclass c, jlong peer, jstring text, int x,
                    int y)
{
  const char* chars = (*e)->GetStringUTFChars(e, text, 0);
  NSString* string = [[NSString alloc] initWithUTF8String: chars];
  (*e)->ReleaseStringUTFChars(e, text, chars);

  // Create text attributes
  NSDictionary *textAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0]};

  // Create string drawing context
  NSStringDrawingContext *drawingContext = [[NSStringDrawingContext alloc] init];
  drawingContext.minimumScaleFactor = 0.5; // Half the font size

  CGSize textsize = [string sizeWithAttributes:textAttributes];
  CGRect drawRect = CGRectMake(x - (textsize.width / 2.0), y - (textsize.height / 2.0), textsize.width, textsize.height);
  [string drawWithRect:drawRect
               options:NSStringDrawingUsesLineFragmentOrigin
            attributes:textAttributes
               context:drawingContext];
}
