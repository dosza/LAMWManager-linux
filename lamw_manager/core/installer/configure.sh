#!/bin/bash

declare -i X11_INDEX=11
declare -i GTK2_INDEX=265
declare -i GDK_INDEX=278
declare -i CAIRO_INDEX=292
declare -i PANGO_INDEX=326
declare -i XTST_INDEX=328
declare -i ATK_INDEX=362
declare -i FREEGLUT_INDEX=366

declare -A LIBS_DEB_EQUIVALENT=(
	['libgdk-x11-2.0.so']=libgtk2.0-dev
	['libgtk-x11-2.0.so']=libx11-dev
	['libgdk_pixbuf-2.0.so']=libgdk-pixbuf2.0-dev
	['libgdk_pixbuf_xlib-2.0.so']=libgdk-pixbuf2.0-dev
	['libcairo-gobject.so']=libcairo2-dev
	['libcairo-script-interpreter.so']=libcairo2-dev
	['libcairo.so']=libcairo2-dev
	['libpango-1.0.so']=libpango1.0-dev
	['libpangocairo-1.0.so']=libpango1.0-dev
	['libpangoft2-1.0.so']=libpango1.0-dev
	['libpangoxft-1.0.so']=libpango1.0-dev
	['libXtst.so']=libxtst-dev
	['libatk-1.0.so']=libatk1.0-dev
	['libglut.so']='freeglut3-deb.so freeglut3-dev'
)



declare -A HEADERS_EQUIVALENT_DEB=(
	[$X11_INDEX]=libx11-dev
	[$GTK2_INDEX]=libgtk2.0-dev
	[$GDK_INDEX]=libgdk-pixbuf2.0-dev
	[$CAIRO_INDEX]=libcairo2-dev
	[$PANGO_INDEX]=libpango1.0-dev
	[$XTST_INDEX]=libxtst-dev
	[$ATK_INDEX]=libatk1.0-dev
	[$FREEGLUT_INDEX]=freeglut3-dev
)



RESUL=1
SOFTWARES=(
	ld
	as
	strip
	gdb
	gcc
	make
	git
	wget 
	jq
	xmlstarlet
	unzip
	zenity
	bc
)

LIBS=(
	libgdk-x11-2.0.so
	libgtk-x11-2.0.so
	libgdk_pixbuf-2.0.so
	libgdk_pixbuf_xlib-2.0.so
	libcairo-gobject.so
	libcairo-script-interpreter.so
	libcairo.so
	libpango-1.0.so
	libpangocairo-1.0.so
	libpangoft2-1.0.so
	libpangoxft-1.0.so
	libXtst.so
	libatk-1.0.so
	libglut.so
)

HEADERS=(
	/usr/include/X11/ImUtil.h 
	/usr/include/X11/XKBlib.h 
	/usr/include/X11/Xcms.h   
	/usr/include/X11/Xlib.h
	/usr/include/X11/XlibConf.h 
	/usr/include/X11/Xlibint.h 
	/usr/include/X11/Xlocale.h 
	/usr/include/X11/Xregion.h
	/usr/include/X11/Xresource.h
	/usr/include/X11/Xutil.h
	/usr/include/X11/cursorfont.h
	/usr/include/X11/extensions/XKBgeom.h
	/usr/include/gtk-2.0/gdk/gdk.h
	/usr/include/gtk-2.0/gdk/gdkapplaunchcontext.h
	/usr/include/gtk-2.0/gdk/gdkcairo.h
	/usr/include/gtk-2.0/gdk/gdkcolor.h
	/usr/include/gtk-2.0/gdk/gdkcursor.h
	/usr/include/gtk-2.0/gdk/gdkdisplay.h
	/usr/include/gtk-2.0/gdk/gdkdisplaymanager.h
	/usr/include/gtk-2.0/gdk/gdkdnd.h
	/usr/include/gtk-2.0/gdk/gdkdrawable.h
	/usr/include/gtk-2.0/gdk/gdkenumtypes.h
	/usr/include/gtk-2.0/gdk/gdkevents.h
	/usr/include/gtk-2.0/gdk/gdkfont.h
	/usr/include/gtk-2.0/gdk/gdkgc.h
	/usr/include/gtk-2.0/gdk/gdki18n.h
	/usr/include/gtk-2.0/gdk/gdkimage.h
	/usr/include/gtk-2.0/gdk/gdkinput.h
	/usr/include/gtk-2.0/gdk/gdkkeys.h
	/usr/include/gtk-2.0/gdk/gdkkeysyms-compat.h
	/usr/include/gtk-2.0/gdk/gdkkeysyms.h
	/usr/include/gtk-2.0/gdk/gdkpango.h
	/usr/include/gtk-2.0/gdk/gdkpixbuf.h
	/usr/include/gtk-2.0/gdk/gdkpixmap.h
	/usr/include/gtk-2.0/gdk/gdkprivate.h
	/usr/include/gtk-2.0/gdk/gdkproperty.h
	/usr/include/gtk-2.0/gdk/gdkregion.h
	/usr/include/gtk-2.0/gdk/gdkrgb.h
	/usr/include/gtk-2.0/gdk/gdkscreen.h
	/usr/include/gtk-2.0/gdk/gdkselection.h
	/usr/include/gtk-2.0/gdk/gdkspawn.h
	/usr/include/gtk-2.0/gdk/gdktestutils.h
	/usr/include/gtk-2.0/gdk/gdktypes.h
	/usr/include/gtk-2.0/gdk/gdkvisual.h
	/usr/include/gtk-2.0/gdk/gdkwindow.h
	/usr/include/gtk-2.0/gdk/gdkx.h
	/usr/include/gtk-2.0/gtk/gtk.h
	/usr/include/gtk-2.0/gtk/gtkaboutdialog.h
	/usr/include/gtk-2.0/gtk/gtkaccelgroup.h
	/usr/include/gtk-2.0/gtk/gtkaccellabel.h
	/usr/include/gtk-2.0/gtk/gtkaccelmap.h
	/usr/include/gtk-2.0/gtk/gtkaccessible.h
	/usr/include/gtk-2.0/gtk/gtkaction.h
	/usr/include/gtk-2.0/gtk/gtkactiongroup.h
	/usr/include/gtk-2.0/gtk/gtkactivatable.h
	/usr/include/gtk-2.0/gtk/gtkadjustment.h
	/usr/include/gtk-2.0/gtk/gtkalignment.h
	/usr/include/gtk-2.0/gtk/gtkarrow.h
	/usr/include/gtk-2.0/gtk/gtkaspectframe.h
	/usr/include/gtk-2.0/gtk/gtkassistant.h
	/usr/include/gtk-2.0/gtk/gtkbbox.h
	/usr/include/gtk-2.0/gtk/gtkbin.h
	/usr/include/gtk-2.0/gtk/gtkbindings.h
	/usr/include/gtk-2.0/gtk/gtkbox.h
	/usr/include/gtk-2.0/gtk/gtkbuildable.h
	/usr/include/gtk-2.0/gtk/gtkbuilder.h
	/usr/include/gtk-2.0/gtk/gtkbutton.h
	/usr/include/gtk-2.0/gtk/gtkcalendar.h
	/usr/include/gtk-2.0/gtk/gtkcelleditable.h
	/usr/include/gtk-2.0/gtk/gtkcelllayout.h
	/usr/include/gtk-2.0/gtk/gtkcellrenderer.h
	/usr/include/gtk-2.0/gtk/gtkcellrendereraccel.h
	/usr/include/gtk-2.0/gtk/gtkcellrenderercombo.h
	/usr/include/gtk-2.0/gtk/gtkcellrendererpixbuf.h
	/usr/include/gtk-2.0/gtk/gtkcellrendererprogress.h
	/usr/include/gtk-2.0/gtk/gtkcellrendererspin.h
	/usr/include/gtk-2.0/gtk/gtkcellrendererspinner.h
	/usr/include/gtk-2.0/gtk/gtkcellrenderertext.h
	/usr/include/gtk-2.0/gtk/gtkcellrenderertoggle.h
	/usr/include/gtk-2.0/gtk/gtkcellview.h
	/usr/include/gtk-2.0/gtk/gtkcheckbutton.h
	/usr/include/gtk-2.0/gtk/gtkcheckmenuitem.h
	/usr/include/gtk-2.0/gtk/gtkclipboard.h
	/usr/include/gtk-2.0/gtk/gtkclist.h
	/usr/include/gtk-2.0/gtk/gtkcolorbutton.h
	/usr/include/gtk-2.0/gtk/gtkcolorsel.h
	/usr/include/gtk-2.0/gtk/gtkcolorseldialog.h
	/usr/include/gtk-2.0/gtk/gtkcombo.h
	/usr/include/gtk-2.0/gtk/gtkcombobox.h
	/usr/include/gtk-2.0/gtk/gtkcomboboxentry.h
	/usr/include/gtk-2.0/gtk/gtkcomboboxtext.h
	/usr/include/gtk-2.0/gtk/gtkcontainer.h
	/usr/include/gtk-2.0/gtk/gtkctree.h
	/usr/include/gtk-2.0/gtk/gtkcurve.h
	/usr/include/gtk-2.0/gtk/gtkdebug.h
	/usr/include/gtk-2.0/gtk/gtkdialog.h
	/usr/include/gtk-2.0/gtk/gtkdnd.h
	/usr/include/gtk-2.0/gtk/gtkdrawingarea.h
	/usr/include/gtk-2.0/gtk/gtkeditable.h
	/usr/include/gtk-2.0/gtk/gtkentry.h
	/usr/include/gtk-2.0/gtk/gtkentrybuffer.h
	/usr/include/gtk-2.0/gtk/gtkentrycompletion.h
	/usr/include/gtk-2.0/gtk/gtkenums.h
	/usr/include/gtk-2.0/gtk/gtkeventbox.h
	/usr/include/gtk-2.0/gtk/gtkexpander.h
	/usr/include/gtk-2.0/gtk/gtkfilechooser.h
	/usr/include/gtk-2.0/gtk/gtkfilechooserbutton.h
	/usr/include/gtk-2.0/gtk/gtkfilechooserdialog.h
	/usr/include/gtk-2.0/gtk/gtkfilechooserwidget.h
	/usr/include/gtk-2.0/gtk/gtkfilefilter.h
	/usr/include/gtk-2.0/gtk/gtkfilesel.h
	/usr/include/gtk-2.0/gtk/gtkfixed.h
	/usr/include/gtk-2.0/gtk/gtkfontbutton.h
	/usr/include/gtk-2.0/gtk/gtkfontsel.h
	/usr/include/gtk-2.0/gtk/gtkframe.h
	/usr/include/gtk-2.0/gtk/gtkgamma.h
	/usr/include/gtk-2.0/gtk/gtkgc.h
	/usr/include/gtk-2.0/gtk/gtkhandlebox.h
	/usr/include/gtk-2.0/gtk/gtkhbbox.h
	/usr/include/gtk-2.0/gtk/gtkhbox.h
	/usr/include/gtk-2.0/gtk/gtkhpaned.h
	/usr/include/gtk-2.0/gtk/gtkhruler.h
	/usr/include/gtk-2.0/gtk/gtkhscale.h
	/usr/include/gtk-2.0/gtk/gtkhscrollbar.h
	/usr/include/gtk-2.0/gtk/gtkhseparator.h
	/usr/include/gtk-2.0/gtk/gtkhsv.h
	/usr/include/gtk-2.0/gtk/gtkiconfactory.h
	/usr/include/gtk-2.0/gtk/gtkicontheme.h
	/usr/include/gtk-2.0/gtk/gtkiconview.h
	/usr/include/gtk-2.0/gtk/gtkimage.h
	/usr/include/gtk-2.0/gtk/gtkimagemenuitem.h
	/usr/include/gtk-2.0/gtk/gtkimcontext.h
	/usr/include/gtk-2.0/gtk/gtkimcontextsimple.h
	/usr/include/gtk-2.0/gtk/gtkimmodule.h
	/usr/include/gtk-2.0/gtk/gtkimmulticontext.h
	/usr/include/gtk-2.0/gtk/gtkinfobar.h
	/usr/include/gtk-2.0/gtk/gtkinputdialog.h
	/usr/include/gtk-2.0/gtk/gtkinvisible.h
	/usr/include/gtk-2.0/gtk/gtkitem.h
	/usr/include/gtk-2.0/gtk/gtkitemfactory.h
	/usr/include/gtk-2.0/gtk/gtklabel.h
	/usr/include/gtk-2.0/gtk/gtklayout.h
	/usr/include/gtk-2.0/gtk/gtklinkbutton.h
	/usr/include/gtk-2.0/gtk/gtklist.h
	/usr/include/gtk-2.0/gtk/gtklistitem.h
	/usr/include/gtk-2.0/gtk/gtkliststore.h
	/usr/include/gtk-2.0/gtk/gtkmain.h
	/usr/include/gtk-2.0/gtk/gtkmarshal.h
	/usr/include/gtk-2.0/gtk/gtkmenu.h
	/usr/include/gtk-2.0/gtk/gtkmenubar.h
	/usr/include/gtk-2.0/gtk/gtkmenuitem.h
	/usr/include/gtk-2.0/gtk/gtkmenushell.h
	/usr/include/gtk-2.0/gtk/gtkmenutoolbutton.h
	/usr/include/gtk-2.0/gtk/gtkmessagedialog.h
	/usr/include/gtk-2.0/gtk/gtkmisc.h
	/usr/include/gtk-2.0/gtk/gtkmodules.h
	/usr/include/gtk-2.0/gtk/gtkmountoperation.h
	/usr/include/gtk-2.0/gtk/gtknotebook.h
	/usr/include/gtk-2.0/gtk/gtkobject.h
	/usr/include/gtk-2.0/gtk/gtkoffscreenwindow.h
	/usr/include/gtk-2.0/gtk/gtkoldeditable.h
	/usr/include/gtk-2.0/gtk/gtkoptionmenu.h
	/usr/include/gtk-2.0/gtk/gtkorientable.h
	/usr/include/gtk-2.0/gtk/gtkpagesetup.h
	/usr/include/gtk-2.0/gtk/gtkpaned.h
	/usr/include/gtk-2.0/gtk/gtkpapersize.h
	/usr/include/gtk-2.0/gtk/gtkpixmap.h
	/usr/include/gtk-2.0/gtk/gtkplug.h
	/usr/include/gtk-2.0/gtk/gtkpreview.h
	/usr/include/gtk-2.0/gtk/gtkprintcontext.h
	/usr/include/gtk-2.0/gtk/gtkprintoperation.h
	/usr/include/gtk-2.0/gtk/gtkprintoperationpreview.h
	/usr/include/gtk-2.0/gtk/gtkprintsettings.h
	/usr/include/gtk-2.0/gtk/gtkprivate.h
	/usr/include/gtk-2.0/gtk/gtkprogress.h
	/usr/include/gtk-2.0/gtk/gtkprogressbar.h
	/usr/include/gtk-2.0/gtk/gtkradioaction.h
	/usr/include/gtk-2.0/gtk/gtkradiobutton.h
	/usr/include/gtk-2.0/gtk/gtkradiomenuitem.h
	/usr/include/gtk-2.0/gtk/gtkradiotoolbutton.h
	/usr/include/gtk-2.0/gtk/gtkrange.h
	/usr/include/gtk-2.0/gtk/gtkrc.h
	/usr/include/gtk-2.0/gtk/gtkrecentaction.h
	/usr/include/gtk-2.0/gtk/gtkrecentchooser.h
	/usr/include/gtk-2.0/gtk/gtkrecentchooserdialog.h
	/usr/include/gtk-2.0/gtk/gtkrecentchoosermenu.h
	/usr/include/gtk-2.0/gtk/gtkrecentchooserwidget.h
	/usr/include/gtk-2.0/gtk/gtkrecentfilter.h
	/usr/include/gtk-2.0/gtk/gtkrecentmanager.h
	/usr/include/gtk-2.0/gtk/gtkruler.h
	/usr/include/gtk-2.0/gtk/gtkscale.h
	/usr/include/gtk-2.0/gtk/gtkscalebutton.h
	/usr/include/gtk-2.0/gtk/gtkscrollbar.h
	/usr/include/gtk-2.0/gtk/gtkscrolledwindow.h
	/usr/include/gtk-2.0/gtk/gtkselection.h
	/usr/include/gtk-2.0/gtk/gtkseparator.h
	/usr/include/gtk-2.0/gtk/gtkseparatormenuitem.h
	/usr/include/gtk-2.0/gtk/gtkseparatortoolitem.h
	/usr/include/gtk-2.0/gtk/gtksettings.h
	/usr/include/gtk-2.0/gtk/gtkshow.h
	/usr/include/gtk-2.0/gtk/gtksignal.h
	/usr/include/gtk-2.0/gtk/gtksizegroup.h
	/usr/include/gtk-2.0/gtk/gtksocket.h
	/usr/include/gtk-2.0/gtk/gtkspinbutton.h
	/usr/include/gtk-2.0/gtk/gtkspinner.h
	/usr/include/gtk-2.0/gtk/gtkstatusbar.h
	/usr/include/gtk-2.0/gtk/gtkstatusicon.h
	/usr/include/gtk-2.0/gtk/gtkstock.h
	/usr/include/gtk-2.0/gtk/gtkstyle.h
	/usr/include/gtk-2.0/gtk/gtktable.h
	/usr/include/gtk-2.0/gtk/gtktearoffmenuitem.h
	/usr/include/gtk-2.0/gtk/gtktestutils.h
	/usr/include/gtk-2.0/gtk/gtktext.h
	/usr/include/gtk-2.0/gtk/gtktextbuffer.h
	/usr/include/gtk-2.0/gtk/gtktextbufferrichtext.h
	/usr/include/gtk-2.0/gtk/gtktextchild.h
	/usr/include/gtk-2.0/gtk/gtktextdisplay.h
	/usr/include/gtk-2.0/gtk/gtktextiter.h
	/usr/include/gtk-2.0/gtk/gtktextlayout.h
	/usr/include/gtk-2.0/gtk/gtktextmark.h
	/usr/include/gtk-2.0/gtk/gtktexttag.h
	/usr/include/gtk-2.0/gtk/gtktexttagtable.h
	/usr/include/gtk-2.0/gtk/gtktextview.h
	/usr/include/gtk-2.0/gtk/gtktipsquery.h
	/usr/include/gtk-2.0/gtk/gtktoggleaction.h
	/usr/include/gtk-2.0/gtk/gtktogglebutton.h
	/usr/include/gtk-2.0/gtk/gtktoggletoolbutton.h
	/usr/include/gtk-2.0/gtk/gtktoolbar.h
	/usr/include/gtk-2.0/gtk/gtktoolbutton.h
	/usr/include/gtk-2.0/gtk/gtktoolitem.h
	/usr/include/gtk-2.0/gtk/gtktoolitemgroup.h
	/usr/include/gtk-2.0/gtk/gtktoolpalette.h
	/usr/include/gtk-2.0/gtk/gtktoolshell.h
	/usr/include/gtk-2.0/gtk/gtktooltip.h
	/usr/include/gtk-2.0/gtk/gtktooltips.h
	/usr/include/gtk-2.0/gtk/gtktree.h
	/usr/include/gtk-2.0/gtk/gtktreednd.h
	/usr/include/gtk-2.0/gtk/gtktreeitem.h
	/usr/include/gtk-2.0/gtk/gtktreemodel.h
	/usr/include/gtk-2.0/gtk/gtktreemodelfilter.h
	/usr/include/gtk-2.0/gtk/gtktreemodelsort.h
	/usr/include/gtk-2.0/gtk/gtktreeselection.h
	/usr/include/gtk-2.0/gtk/gtktreesortable.h
	/usr/include/gtk-2.0/gtk/gtktreestore.h
	/usr/include/gtk-2.0/gtk/gtktreeview.h
	/usr/include/gtk-2.0/gtk/gtktreeviewcolumn.h
	/usr/include/gtk-2.0/gtk/gtktypebuiltins.h
	/usr/include/gtk-2.0/gtk/gtktypeutils.h
	/usr/include/gtk-2.0/gtk/gtkuimanager.h
	/usr/include/gtk-2.0/gtk/gtkvbbox.h
	/usr/include/gtk-2.0/gtk/gtkvbox.h
	/usr/include/gtk-2.0/gtk/gtkversion.h
	/usr/include/gtk-2.0/gtk/gtkviewport.h
	/usr/include/gtk-2.0/gtk/gtkvolumebutton.h
	/usr/include/gtk-2.0/gtk/gtkvpaned.h
	/usr/include/gtk-2.0/gtk/gtkvruler.h
	/usr/include/gtk-2.0/gtk/gtkvscale.h
	/usr/include/gtk-2.0/gtk/gtkvscrollbar.h
	/usr/include/gtk-2.0/gtk/gtkvseparator.h
	/usr/include/gtk-2.0/gtk/gtkwidget.h
	/usr/include/gtk-2.0/gtk/gtkwindow.h
	/usr/include/gtk-unix-print-2.0/gtk/gtkpagesetupunixdialog.h
	/usr/include/gtk-unix-print-2.0/gtk/gtkprinter.h
	/usr/include/gtk-unix-print-2.0/gtk/gtkprintjob.h
	/usr/include/gtk-unix-print-2.0/gtk/gtkprintunixdialog.h
	/usr/include/gtk-unix-print-2.0/gtk/gtkunixprint.h
	/usr/include/gdk-pixbuf-2.0/gdk-pixbuf/gdk-pixbuf-animation.h
	/usr/include/gdk-pixbuf-2.0/gdk-pixbuf/gdk-pixbuf-autocleanups.h
	/usr/include/gdk-pixbuf-2.0/gdk-pixbuf/gdk-pixbuf-core.h
	/usr/include/gdk-pixbuf-2.0/gdk-pixbuf/gdk-pixbuf-enum-types.h
	/usr/include/gdk-pixbuf-2.0/gdk-pixbuf/gdk-pixbuf-features.h
	/usr/include/gdk-pixbuf-2.0/gdk-pixbuf/gdk-pixbuf-io.h
	/usr/include/gdk-pixbuf-2.0/gdk-pixbuf/gdk-pixbuf-loader.h
	/usr/include/gdk-pixbuf-2.0/gdk-pixbuf/gdk-pixbuf-macros.h
	/usr/include/gdk-pixbuf-2.0/gdk-pixbuf/gdk-pixbuf-marshal.h
	/usr/include/gdk-pixbuf-2.0/gdk-pixbuf/gdk-pixbuf-simple-anim.h
	/usr/include/gdk-pixbuf-2.0/gdk-pixbuf/gdk-pixbuf-transform.h
	/usr/include/gdk-pixbuf-2.0/gdk-pixbuf/gdk-pixbuf.h
	/usr/include/gdk-pixbuf-2.0/gdk-pixbuf/gdk-pixdata.h
#	/usr/include/gdk-pixbuf-2.0/gdk-pixbuf-xlib/gdk-pixbuf-xlib.h
#	/usr/include/gdk-pixbuf-2.0/gdk-pixbuf-xlib/gdk-pixbuf-xlibrgb.h
	/usr/include/cairo/cairo-deprecated.h
	/usr/include/cairo/cairo-features.h
	/usr/include/cairo/cairo-ft.h
#	/usr/include/cairo/cairo-gobject.h
	/usr/include/cairo/cairo-pdf.h
	/usr/include/cairo/cairo-ps.h
	/usr/include/cairo/cairo-script-interpreter.h
	/usr/include/cairo/cairo-script.h
	/usr/include/cairo/cairo-svg.h
	#/usr/include/cairo/cairo-tee.h
	/usr/include/cairo/cairo-version.h
	/usr/include/cairo/cairo-xcb.h
	/usr/include/cairo/cairo-xlib-xrender.h
	/usr/include/cairo/cairo-xlib.h
	/usr/include/cairo/cairo.h
	/usr/include/pango-1.0/pango/pango-attributes.h
	/usr/include/pango-1.0/pango/pango-bidi-type.h
	/usr/include/pango-1.0/pango/pango-break.h
	/usr/include/pango-1.0/pango/pango-context.h
	/usr/include/pango-1.0/pango/pango-coverage.h
	/usr/include/pango-1.0/pango/pango-direction.h
	/usr/include/pango-1.0/pango/pango-engine.h
	/usr/include/pango-1.0/pango/pango-enum-types.h
	/usr/include/pango-1.0/pango/pango-features.h
	/usr/include/pango-1.0/pango/pango-font.h
	/usr/include/pango-1.0/pango/pango-fontmap.h
	/usr/include/pango-1.0/pango/pango-fontset.h
	/usr/include/pango-1.0/pango/pango-glyph-item.h
	/usr/include/pango-1.0/pango/pango-glyph.h
	/usr/include/pango-1.0/pango/pango-gravity.h
	/usr/include/pango-1.0/pango/pango-item.h
	/usr/include/pango-1.0/pango/pango-language.h
	/usr/include/pango-1.0/pango/pango-layout.h
	/usr/include/pango-1.0/pango/pango-matrix.h
	/usr/include/pango-1.0/pango/pango-modules.h
	/usr/include/pango-1.0/pango/pango-ot.h
	/usr/include/pango-1.0/pango/pango-renderer.h
	/usr/include/pango-1.0/pango/pango-script.h
	/usr/include/pango-1.0/pango/pango-tabs.h
	/usr/include/pango-1.0/pango/pango-types.h
	/usr/include/pango-1.0/pango/pango-utils.h
	/usr/include/pango-1.0/pango/pango-version-macros.h
	/usr/include/pango-1.0/pango/pango.h
	/usr/include/pango-1.0/pango/pangocairo.h
	/usr/include/pango-1.0/pango/pangofc-decoder.h
	/usr/include/pango-1.0/pango/pangofc-font.h
	/usr/include/pango-1.0/pango/pangofc-fontmap.h
	/usr/include/pango-1.0/pango/pangoft2.h
	/usr/include/pango-1.0/pango/pangoxft-render.h
	/usr/include/pango-1.0/pango/pangoxft.h
	/usr/include/X11/extensions/XTest.h
	/usr/include/X11/extensions/record.h
	/usr/include/atk-1.0/atk/atk-enum-types.h
	/usr/include/atk-1.0/atk/atk.h
	/usr/include/atk-1.0/atk/atkaction.h
	/usr/include/atk-1.0/atk/atkcomponent.h
	/usr/include/atk-1.0/atk/atkdocument.h
	/usr/include/atk-1.0/atk/atkeditabletext.h
	/usr/include/atk-1.0/atk/atkgobjectaccessible.h
	/usr/include/atk-1.0/atk/atkhyperlink.h
	/usr/include/atk-1.0/atk/atkhyperlinkimpl.h
	/usr/include/atk-1.0/atk/atkhypertext.h
	/usr/include/atk-1.0/atk/atkimage.h
	/usr/include/atk-1.0/atk/atkmisc.h
	/usr/include/atk-1.0/atk/atknoopobject.h
	/usr/include/atk-1.0/atk/atknoopobjectfactory.h
	/usr/include/atk-1.0/atk/atkobject.h
	/usr/include/atk-1.0/atk/atkobjectfactory.h
	/usr/include/atk-1.0/atk/atkplug.h
	/usr/include/atk-1.0/atk/atkrange.h
	/usr/include/atk-1.0/atk/atkregistry.h
	/usr/include/atk-1.0/atk/atkrelation.h
	/usr/include/atk-1.0/atk/atkrelationset.h
	/usr/include/atk-1.0/atk/atkrelationtype.h
	/usr/include/atk-1.0/atk/atkselection.h
	/usr/include/atk-1.0/atk/atksocket.h
	/usr/include/atk-1.0/atk/atkstate.h
	/usr/include/atk-1.0/atk/atkstateset.h
	/usr/include/atk-1.0/atk/atkstreamablecontent.h
	/usr/include/atk-1.0/atk/atktable.h
	/usr/include/atk-1.0/atk/atktablecell.h
	/usr/include/atk-1.0/atk/atktext.h
	/usr/include/atk-1.0/atk/atkutil.h
	/usr/include/atk-1.0/atk/atkvalue.h
	/usr/include/atk-1.0/atk/atkversion.h
	/usr/include/atk-1.0/atk/atkwindow.h
	/usr/include/GL/freeglut.h
	/usr/include/GL/freeglut_ext.h
	/usr/include/GL/freeglut_std.h
	/usr/include/GL/glut.h
)

MESSAGE_INSTALL='Install on your system the package equivalent to:'


showPackageNameByIndex(){
	local -i index=$1

	if [ $index -le  $X11_INDEX ]; then 
		echo "$MESSAGE_INSTALL: ${HEADERS_EQUIVALENT_DEB[$X11_INDEX]}"
		
		elif [ $index -le $GTK2_INDEX ]; then 
			echo "$MESSAGE_INSTALL: ${HEADERS_EQUIVALENT_DEB[$GTK2_INDEX]}"
		
		elif [ $index -le $GDK_INDEX ]; then 
			echo "$MESSAGE_INSTALL: ${HEADERS_EQUIVALENT_DEB[$GDK_INDEX]}"
		
		elif [ $index -le $CAIRO_INDEX ]; then 
			echo "$MESSAGE_INSTALL: ${HEADERS_EQUIVALENT_DEB[$CAIRO_INDEX]}"
		
		elif [ $index -le $PANGO_INDEX ]; then 
			echo "$MESSAGE_INSTALL: ${HEADERS_EQUIVALENT_DEB[$PANGO_INDEX]}"
		
		elif [ $index -le $XTST_INDEX ]; then 
			echo "$MESSAGE_INSTALL: ${HEADERS_EQUIVALENT_DEB[$XTST_INDEX]}"
		
		elif [ $index -le $ATK_INDEX ]; then 
			echo "$MESSAGE_INSTALL: ${HEADERS_EQUIVALENT_DEB[$ATK_INDEX]}"
		
		elif [ $index -le $FREEGLUT_INDEX ]; then 
			echo "$MESSAGE_INSTALL: ${HEADERS_EQUIVALENT_DEB[$FREEGLUT_INDEX]}"
		fi

}

printOK(){
	printf "%s\r" "${FILLER:${#1}}${VERDE} [OK]${NORMAL}"
}
printFail(){
	printf "%s\n" "${FILLER:${#1}}${VERMELHO} [FAILS]${NORMAL}"
	echo "Please, get more info in https://github.com/dosza/LAMWManager-linux/blob/master/lamw_manager/docs/other-distros-info.md#compatible-linux-distro"
}

systemHasLibsToBuildLazarus(){
	local -i count=0
	for i in ${LIBS[@]}; do
		printf "%b" "Checking $i"
		if find /usr /lib64 -name $i &>/dev/null; then
			printOK "$i"
			((count++))
		else 
			printFail "$i"
			echo "$MESSAGE_INSTALL:" "${LIBS_DEB_EQUIVALENT[$i]}"
			exit 1
		fi
	done
	echo ""
	[ ${count} = ${#LIBS[@]} ]
}



systemHasHeadersToBuildLazarus(){
	local -i count=0
	local libs
	
	for i in ${HEADERS[@]}; do
		libs="$(basename $i)"
		printf "Checking $libs"
		if [ -e $i ]; then 
			printOK "$libs"
		else 
			printFail "$libs"
			showPackageNameByIndex "$count"
			exit 1
		fi
		((count++))
	done
	echo ""
}



systemHasToolsToRunLamwManager(){
	local -i count=0
	for i in ${SOFTWARES[@]};do
		printf "%b" "Checking $i" 
		if which $i &>/dev/null; then 
			((count++))
			printOK "$i"
		else
			printFail "$i"
			exit 1
		fi
	done
	echo ""

	[ $count = ${#SOFTWARES[@]} ]
}


CheckIfSystemNeedTerminalMitigation(){
	[ $IS_DEBIAN = 1 ] && return 
	
	local desktop_env="$LAMW_USER_DESKTOP_SESSION $LAMW_USER_XDG_CURRENT_DESKTOP"
	local gnome_regex="(GNOME)"
	local xfce_regex="(XFCE)"
	local cinnamon_regex="(X\-CINNAMON)"

	if 	[[ "$desktop_env" =~ $gnome_regex ]] ||
		[[ "$desktop_env" =~ $cinnamon_regex ]] || 
		[[ "$desktop_env" =~ $xfce_regex ]]; then 
			NEED_XFCE_MITIGATION=1
			SOFTWARES+=(xterm)
			if [ $UID != 0 ]; then 
				>"$IGNORE_XFCE_LAMW_ERROR_PATH"
			fi
	fi
}

CheckIfYourLinuxIsSupported(){
	CheckIfSystemNeedTerminalMitigation
	if systemHasToolsToRunLamwManager; then 
		if systemHasHeadersToBuildLazarus ; then
			if systemHasLibsToBuildLazarus ;then
				RESUL=0
			fi
		fi
	fi
}
