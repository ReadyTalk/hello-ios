-keep class Hello {
   <init>(long);
   *** draw(int, int, int, int);
   *** dispose();
 }

-repackageclasses ''
-allowaccessmodification
-dontpreverify
