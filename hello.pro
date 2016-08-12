-keep class Hello {
   <init>(long);
   *** draw(...);
   *** dispose();
 }

-repackageclasses ''
-allowaccessmodification
-dontpreverify
