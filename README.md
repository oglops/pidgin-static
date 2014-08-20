Pidgin with lwqq static build 
===================

本来是想得到一个portable的pidgin，这样可以拷给别人用，因为在公司没权限装.
（但是失败了，lz科技实力不足，成果还是dynamic的，不过至少这可以一键安装pidgin了，还有所有推荐插件，包括 lwqq / pidgin-lwqq / pidgin-sendscreenshot / pidgin-gnome-keyring / pidgin-libnotify / Recent-Contacts-Plugin-for-Pidgin ）
运行 ./build.sh, 然后就可以倒杯茶等着了，编译好的pidgin可以在 target/bin 里找到

Build dependencies
------------------

    # CentOS 6.5
    $ yum install gcc gcc-c++ make cmake pkgconfig glib-devel libpurple-devel

Build & "install"
-----------------

    $ ./build.sh
    # ... wait ...
    # binaries can be found in ./target/bin/


Debug
-----

On the top-level of the project, run:

	$ . env.source
	
You can then enter the source folders and make the compilation yourself

	$ cd build/pidgin-lwqq*
	$ ./configure --prefix=$TARGET_DIR #...
	# ...

Remaining links
---------------

...

TODO
----

 * make pidgin portable
 
