class Lzlib < Formula
  desc "Data compression library"
  homepage "https://www.nongnu.org/lzip/lzlib.html"
  url "https://download.savannah.gnu.org/releases/lzip/lzlib/lzlib-1.15.tar.gz"
  mirror "https://download-mirror.savannah.gnu.org/releases/lzip/lzlib/lzlib-1.15.tar.gz"
  sha256 "4afab907a46d5a7d14e927a1080c3f4d7e3ca5a0f9aea81747d8fed0292377ff"
  license "BSD-2-Clause"
  revision 1

  livecheck do
    url "https://download.savannah.gnu.org/releases/lzip/lzlib/"
    regex(/href=.*?lzlib[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "e0de833c618fd656ff351fcd981f3aa30d214301bc300497f5d6f573f5421203"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "87bcb4061bb953be6a3a89673b3671923af705d5cb38856b5859fb71f6dc1128"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "e7d49c0b61af344aec1da7f037ec59ce9c36f79a9b7606794e15697c7b04f0ca"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "f957b6e8a1170b0fe93bfca8004cb9467d8496688f56999c6088aecd90ad59e6"
    sha256 cellar: :any_skip_relocation, sonoma:        "9e294db70263a4a544a032cb1574a8493d0a0e1830ccaccd5181b8b793fd87ba"
    sha256 cellar: :any_skip_relocation, ventura:       "37d32f4cd2440fa0f6a73492c7e585f037fc6cb189f57dfeb6023e9cd3d7403e"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "a91ac1ac39e250d4245285e4db6581ab1c801b329537933661e418eda81ab976"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "4e55a6c95515ea3ffc18c2486dfbb3819cdfddc6fc7b0a86b11c0c62f81f2cc0"
  end

  on_macos do
    # Change shared library name and flags for macOS
    patch :DATA
  end

  def install
    system "./configure", "--prefix=#{prefix}",
                          "--enable-shared",
                          "CC=#{ENV.cc}",
                          "CFLAGS=#{ENV.cflags}"
    system "make"
    system "make", "check"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <stdint.h>
      #include "lzlib.h"
      int main (void) {
        printf ("%s", LZ_version());
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-llz", "-o", "test"
    assert_equal version.to_s, shell_output("./test")
  end
end

__END__
diff --git a/Makefile.in b/Makefile.in
index 4f99874..8e344d9 100644
--- a/Makefile.in
+++ b/Makefile.in
@@ -28,17 +28,16 @@ lib : $(libname_static) $(libname_shared)
 lib$(libname).a : lzlib.o
 	$(AR) $(ARFLAGS) $@ $<
 
-lib$(libname).so.$(soversion) : lzlib_sh.o
-	$(CC) $(CFLAGS) $(LDFLAGS) -fpic -fPIC -shared -Wl,--soname=$@ -o $@ $< || \
-	$(CC) $(CFLAGS) $(LDFLAGS) -fpic -fPIC -shared -o $@ $<
+lib$(libname).$(soversion).dylib : lzlib_sh.o
+	$(CC) $(CFLAGS) $(LDFLAGS) -fpic -fPIC -dynamiclib -install_name $(libdir)/$@ -compatibility_version $(soversion) -current_version $(pkgversion) -o $@ $<
 
 bin : $(progname_static) $(progname_shared)
 
 $(progname) : $(objs) lib$(libname).a
 	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(objs) lib$(libname).a
 
-$(progname)_shared : $(objs) lib$(libname).so.$(soversion)
-	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(objs) lib$(libname).so.$(soversion)
+$(progname)_shared : $(objs) lib$(libname).$(soversion).dylib
+	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(objs) lib$(libname).$(soversion).dylib
 
 bbexample : bbexample.o lib$(libname).a
 	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ bbexample.o lib$(libname).a
@@ -115,15 +114,13 @@ install-lib : lib
 	  $(INSTALL_DATA) ./lib$(libname).a "$(DESTDIR)$(libdir)/lib$(libname).a" ; \
 	fi
 	if [ -n "$(libname_shared)" ] ; then \
-	  if [ -e "$(DESTDIR)$(libdir)/lib$(libname).so.$(soversion)" ] ; then \
+	  if true; then \
 	    run_ldconfig=no ; \
 	  else run_ldconfig=yes ; \
 	  fi ; \
-	  rm -f "$(DESTDIR)$(libdir)/lib$(libname).so" ; \
-	  rm -f "$(DESTDIR)$(libdir)/lib$(libname).so.$(soversion)" ; \
-	  $(INSTALL_SO) ./lib$(libname).so.$(soversion) "$(DESTDIR)$(libdir)/lib$(libname).so.$(pkgversion)" ; \
-	  cd "$(DESTDIR)$(libdir)" && ln -s lib$(libname).so.$(pkgversion) lib$(libname).so ; \
-	  cd "$(DESTDIR)$(libdir)" && ln -s lib$(libname).so.$(pkgversion) lib$(libname).so.$(soversion) ; \
+	  $(INSTALL_SO) ./lib$(libname).$(soversion).dylib "$(DESTDIR)$(libdir)/lib$(libname).$(pkgversion).dylib" ; \
+	  cd "$(DESTDIR)$(libdir)" && ln -s lib$(libname).$(pkgversion).dylib lib$(libname).dylib ; \
+	  cd "$(DESTDIR)$(libdir)" && ln -s lib$(libname).$(pkgversion).dylib lib$(libname).$(soversion).dylib ; \
 	  if [ "${disable_ldconfig}" != yes ] && [ $${run_ldconfig} = yes ] && \
 	     [ -x "$(LDCONFIG)" ] ; then "$(LDCONFIG)" -n "$(DESTDIR)$(libdir)" || true ; fi ; \
 	fi
diff --git a/configure b/configure
index 90ab72d..e843746 100755
--- a/configure
+++ b/configure
@@ -123,7 +123,7 @@ while [ $# != 0 ] ; do
 		progname_shared=${progname}_shared
 		progname_lzip=${progname}_shared ;;
 	--enable-shared)
-		libname_shared=lib${libname}.so.${soversion}
+		libname_shared=lib${libname}.${soversion}.dylib
 		progname_shared=${progname}_shared
 		progname_lzip=${progname}_shared ;;
 	--disable-ldconfig) disable_ldconfig=yes ;;
