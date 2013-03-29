# Mostly a convenient location to update svn revisions at
MSL32REV=6065
MSL31REV=5515
MSL22REV=6145
MSL16REV=939
MEMBEDDEDREV=6147

all: Makefile.numjobs config.done
	rm -rf build
	rm -f *.uses
	$(MAKE) all-work
	$(MAKE) test uses
	$(MAKE) debian
all-work: modelica3d msl31 msl222 msl16 embeddedsystems

config.done: Makefile
	which rm
	which svn
	which git
	which omc
	which debuild
	which dpkg-buildpackage
	which sha1sum
	which xargs
	which xsltproc
	touch config.done
Makefile.numjobs:
	echo 7 > $@
	echo "*** Setting number of jobs to 5. 1 makes things too slow and 5 threads. Set $@ if you want to change it ***"
msl32: config.done
	./update-library.sh SVN https://svn.modelica.org/projects/Modelica/trunk 6065 "MSL 3.2.1" all
	# Moving ModelicaReference so there is only one package for it
	for f in "build/ModelicaReference 3.2.1"*; do mv "$$f" "`echo $$f | sed 's/ 3.2.1//'`"; done
modelica3d: msl32
	./update-library.sh SVN https://openmodelica.org/svn/OpenModelica/trunk/3rdParty/modelica3d 15181 "Modelica3D" none
	@echo Much more work is needed for Modelica3D. We should move it to an external repository...
	@echo Modelica3D also needs native debian builds
	install -m755 -d "build/ModelicaServices 3.2.1 modelica3d/"
	install -m755 -d "build/ModelicaServices 3.2.1 modelica3d/modbus"
	install -m755 -d "build/ModelicaServices 3.2.1 modelica3d/modcount"
	install -m755 -d "build/ModelicaServices 3.2.1 modelica3d/Modelica3D"
	install -p -m644 "Modelica3D/lib/modbus/src/modelica/modbus/package.mo" "build/ModelicaServices 3.2.1 modelica3d/modbus/package.mo"
	install -p -m644 "Modelica3D/lib/mod3d/src/modelica/Modelica3D 3.2.1/package.mo" "build/ModelicaServices 3.2.1 modelica3d/Modelica3D/package.mo"
	install -p -m644 "Modelica3D/lib/modcount/src/modelica/modcount/package.mo" "build/ModelicaServices 3.2.1 modelica3d/modcount/package.mo"
	install -p -m644 "build/ModelicaServices 3.2.1/package.mo" "build/ModelicaServices 3.2.1 modelica3d/package.mo"
	patch "build/ModelicaServices 3.2.1 modelica3d/package.mo" -p1 < "ModelicaServices 3.2.1 modelica3d.patch"
	find "build/ModelicaServices 3.2.1 modelica3d" -name "*.orig" -exec rm -f "{}" ";"
	svn info --xml "Modelica3D" | xpath -q -e '/info/entry/commit/@revision' | grep -o "[0-9]*" > "build/ModelicaServices 3.2.1 modelica3d.last_change"
	svn log --xml --verbose "Modelica3D" | sed "s,<date>.*</date>,<date>1970-01-01</date>," | sed "s,<author>\(.*\)</author>,<author>none</author><author-svn>\1</author-svn>," | xsltproc svn2cl.xsl - > "build/ModelicaServices 3.2.1 modelica3d.changes"
	cp "build/ModelicaServices 3.2.1.license" "build/ModelicaServices 3.2.1 modelica3d.license"
msl31: config.done
	./update-library.sh SVN https://svn.modelica.org/projects/Modelica/branches/maintenance/3.1 5515 "MSL 3.1" Modelica ModelicaServices
msl222: config.done
	./update-library.sh --encoding "Windows-1252" --std "2.x" --license "modelica1.1" SVN https://svn.modelica.org/projects/Modelica/branches/maintenance/2.2.2 6145 "MSL 2.2.2" all
msl16: config.done
	./update-library.sh --license "modelica1.1" --std "1.x" SVN https://svn.modelica.org/projects/Modelica/tags/V1_6 939 "MSL 1.6" "Modelica 1.6"

embeddedsystems: config.done
	./update-library.sh SVN https://svn.modelica.org/projects/Modelica_EmbeddedSystems/trunk 6147 "Modelica_EmbeddedSystems" Modelica_LinearSystems2
#diff-linearsystems:
#	./diff-library.sh "Modelica_EmbeddedSystems/Modelica_LinearSystems2/" "Modelica_LinearSystems2 2.3" "Modelica_LinearSystems2 2.3.patch"

test: config.done
	rm -f error.log test-valid.*.mos
	find build/*.mo build/*/package.mo -print0 | xargs -0 -n 1 -P `cat Makefile.numjobs` sh -c './test-valid.sh "$$1"' sh
	rm -f error.log test-valid.*.mos
uses: config.done
	find build/*.uses -print0 | xargs -0 -n 1 -P `cat Makefile.numjobs` sh -c './check-uses.sh "$$1"' sh
debian: config.done
	find build/*.hash -print0 | xargs -0 -n 1 -P `cat Makefile.numjobs` sh -c './debian-build.sh "$$1"' sh

clean:
	rm -f *.rev *.uses  test-valid.*.mos config.done
	rm -rf "MSL 3.2.1" "MSL 2.2.2" "MSL 3.1" "MSL 1.6" Modelica3D "Modelica_EmbeddedSystems" "Modelica_LinearSystems2 2.3" build debian-build
