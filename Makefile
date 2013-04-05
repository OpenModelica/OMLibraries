# Mostly a convenient location to update svn revisions
MSL32REV=https://svn.modelica.org/projects/Modelica/trunk 6212
MSL31REV=https://svn.modelica.org/projects/Modelica/branches/maintenance/3.1 6200
MSL22REV=https://svn.modelica.org/projects/Modelica/branches/maintenance/2.2.2 6200
MSL16REV=https://svn.modelica.org/projects/Modelica/tags/V1_6 939
MEMBEDDEDREV=https://svn.modelica.org/projects/Modelica_EmbeddedSystems/trunk 6204
M3DREV=https://github.com/OpenModelica/modelica3d/trunk 16
ADGENKINREV=https://github.com/modelica-3rdparty/ADGenKinetics/trunk 2
BONDGRAPHREV=https://github.com/modelica-3rdparty/BondGraph/trunk 2
BUILDINGSREV=https://github.com/lbl-srg/modelica-buildings/trunk 1292
ICSREV=https://github.com/modelica-3rdparty/IndustrialControlSystems/trunk 6
LINEARMPCREV=https://github.com/modelica-3rdparty/LinearMPC/trunk 8
OPENHYDRAULICSREV=https://github.com/modelica-3rdparty/OpenHydraulics/trunk 17
# This is an unexpected format... package.mo straight in trunk
RTCLREV=https://github.com/modelica-3rdparty/RealTimeCoordinationLibrary/trunk 15
SVN_DIRS="MSL 3.2.1" "MSL 2.2.2" "MSL 3.1" "MSL 1.6" "Modelica3D" "Modelica_EmbeddedSystems" "ADGenKinetics" "BondGraph" "Buildings" "IndustrialControlSystems" "LinearMPC" "OpenHydraulics" "RealTimeCoordinationLibrary"

all: Makefile.numjobs config.done
	rm -rf build
	rm -f *.uses
	$(MAKE) all-work
	$(MAKE) test uses
	$(MAKE) debian
all-work: modelica3d msl31 msl222 msl16 embeddedsystems adgenkin bondgraph buildings ics linearmpc openhydraulics rtcl

config.done: Makefile
	which rm > /dev/null
	which svn > /dev/null
	which git > /dev/null
	which omc > /dev/null
	which debuild > /dev/null
	which dpkg-buildpackage > /dev/null
	which sha1sum > /dev/null
	which xargs > /dev/null
	which xsltproc > /dev/null
	which xpath > /dev/null
	touch config.done
Makefile.numjobs:
	echo 7 > $@
	echo "*** Setting number of jobs to 5. 1 makes things too slow and 5 threads. Set $@ if you want to change it ***"
msl32: config.done
	./update-library.sh --breaks omlibrary-msl32 SVN $(MSL32REV) "MSL 3.2.1" all
	# Moving ModelicaReference so there is only one package for it
	rm -rf build/ModelicaReference build/ModelicaReference.*
	for f in "build/ModelicaReference 3.2.1"*; do mv "$$f" "`echo $$f | sed 's/ 3.2.1//'`"; done
modelica3d: msl32
	./update-library.sh SVN $(M3DREV) "Modelica3D" none
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
	echo `cat "build/ModelicaServices 3.2.1.last_change"`-m3d`svn info --xml "Modelica3D" | xpath -q -e '/info/entry/commit/@revision' | grep -o "[0-9]*"`-om3d`git rev-list HEAD --count "ModelicaServices 3.2.1 modelica3d.patch"` > "build/ModelicaServices 3.2.1 modelica3d.last_change"
	svn log --xml --verbose "Modelica3D" | sed "s,<date>.*</date>,<date>1970-01-01</date>," | sed "s,<author>\(.*\)</author>,<author>none</author><author-svn>\1</author-svn>," | xsltproc svn2cl.xsl - > "build/ModelicaServices 3.2.1 modelica3d.changes"
	cp "build/ModelicaServices 3.2.1.license" "build/ModelicaServices 3.2.1 modelica3d.license"
msl31: config.done
	./update-library.sh SVN $(MSL31REV) "MSL 3.1" Modelica ModelicaServices
msl222: config.done
	./update-library.sh --encoding "Windows-1252" --std "2.x" --license "modelica1.1" SVN $(MSL22REV) "MSL 2.2.2" all
msl16: config.done
	./update-library.sh --license "modelica1.1" --std "1.x" SVN $(MSL16REV) "MSL 1.6" "Modelica 1.6"

embeddedsystems: config.done
	./update-library.sh SVN $(MEMBEDDEDREV) "Modelica_EmbeddedSystems" Modelica_LinearSystems2
#diff-linearsystems:
#	./diff-library.sh "Modelica_EmbeddedSystems/Modelica_LinearSystems2/" "Modelica_LinearSystems2 2.3" "Modelica_LinearSystems2 2.3.patch"
adgenkin: config.done
	./update-library.sh SVN $(ADGENKINREV) "ADGenKinetics" all
bondgraph: config.done
	./update-library.sh --license "gpl3+" SVN $(BONDGRAPHREV) "BondGraph" all
buildings: config.done
	./update-library.sh --license "buildings" SVN $(BUILDINGSREV) "Buildings" Buildings
ics: config.done
	./update-library.sh SVN $(ICSREV) "IndustrialControlSystems" all
linearmpc: config.done
	./update-library.sh SVN $(LINEARMPCREV) "LinearMPC" all
openhydraulics: config.done
	./update-library.sh SVN $(OPENHYDRAULICSREV) "OpenHydraulics" all
rtcl: config.done
	./update-library.sh --encoding "Windows-1252" SVN $(RTCLREV) "RealTimeCoordinationLibrary" self

test: config.done Makefile.numjobs
	rm -f error.log test-valid.*.mos
	find build/*.mo build/*/package.mo -print0 | xargs -0 -n 1 -P `cat Makefile.numjobs` sh -c './test-valid.sh "$$1"' sh
	rm -f error.log test-valid.*.mos
uses: config.done Makefile.numjobs
	find build/*.uses -print0 | xargs -0 -n 1 -P `cat Makefile.numjobs` sh -c './check-uses.sh "$$1"' sh
clean:
	rm -f *.rev *.uses  test-valid.*.mos config.done
	rm -rf build debian-build $(SVN_DIRS)

check-latest: config.done Makefile.numjobs
	echo "Looking for more recent versions of packages"
	find $(SVN_DIRS) -prune -print0 | xargs -0 -n 1 -P `cat Makefile.numjobs` sh -c './check-latest.sh "$$1"' sh

# .remote/control-files: Directory where the list of packages should be stored. Used by a shell-script + apt-ftparchive
# .remote/pool: Directory where the deb-packages and sources should be stored
debian: config.done Makefile.numjobs .remote/control-files .remote/pool
	rm -rf debian-build
	mkdir -p debian-build
	scp "`cat .remote/control-files`/nightly-library-files" .remote/nightly-library-files
	scp "`cat .remote/control-files`/nightly-library-sources" .remote/nightly-library-sources
	find build/*.hash -print0 | xargs -0 -n 1 -P `cat Makefile.numjobs` sh -c './debian-build.sh "$$1"' sh
	./check-debian.sh
	diff -u nightly-library-files .remote/nightly-library-files || true
	diff -u nightly-library-sources .remote/nightly-library-sources || true
upload: config.done .remote/control-files .remote/pool
	scp debian-build/*.deb debian-build/*.tar.gz debian-build/*.dsc "`cat .remote/pool`"
	scp nightly-library-files nightly-library-sources "`cat .remote/control-files`"
