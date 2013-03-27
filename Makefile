all:
	rm -rf build
	rm -f *.uses
	$(MAKE) all-work
	$(MAKE) test
all-work: msl32 msl31 linearsystems msl222

msl32:
	./update-library.sh SVN https://svn.modelica.org/projects/Modelica/trunk 6065 "MSL 3.2.1" all
msl31:
	./update-library.sh SVN https://svn.modelica.org/projects/Modelica/branches/maintenance/3.1 5515 "MSL 3.1" Modelica ModelicaServices
msl222:
	./update-library.sh --encoding "Windows-1252" --std "2.x" SVN https://svn.modelica.org/projects/Modelica/branches/maintenance/2.2.2 6145 "MSL 2.2.2" all

linearsystems:
	./update-library.sh SVN https://svn.modelica.org/projects/Modelica_EmbeddedSystems/trunk 6147 "Modelica_EmbeddedSystems" Modelica_LinearSystems2
#diff-linearsystems:
#	./diff-library.sh "Modelica_EmbeddedSystems/Modelica_LinearSystems2/" "Modelica_LinearSystems2 2.3" "Modelica_LinearSystems2 2.3.patch"

test:
	./test-valid.sh

clean:
	rm -f *.rev *.uses
	rm -rf "MSL 3.2.1" "MSL 2.2.2" "MSL 3.1" "Modelica_EmbeddedSystems" "Modelica_LinearSystems2 2.3"
