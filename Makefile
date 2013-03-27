all:
	rm -rf build
	$(MAKE) all-work
all-work: msl32 msl31 linearsystems msl222
msl32:
	./update-library.sh SVN https://svn.modelica.org/projects/Modelica/trunk 6065 "MSL 3.2.1" "Complex 3.2.1" "Modelica 3.2.1" "ModelicaReference 3.2.1" "ModelicaServices 3.2.1" "ModelicaTest 3.2.1" "ObsoleteModelica3 3.2.1"
msl31:
	./update-library.sh SVN https://svn.modelica.org/projects/Modelica/branches/maintenance/3.1 5515 "MSL 3.1" "Modelica 3.1" "ModelicaServices 1.0"
linearsystems:
	./update-library.sh SVN https://svn.modelica.org/projects/Modelica_EmbeddedSystems/trunk 6145 "Modelica_EmbeddedSystems" "Modelica_LinearSystems2 2.3"
diff-linearsystems:
	./diff-library.sh "Modelica_EmbeddedSystems/Modelica_LinearSystems2" "build/Modelica_LinearSystems2 2.3" "Modelica_LinearSystems2 2.3.diff"
msl222:
	./update-library.sh --encoding "Windows-1252" SVN https://svn.modelica.org/projects/Modelica/branches/maintenance/2.2.2 6145 "MSL 2.2.2" "Modelica 2.2.2"

test:
	./test-valid.sh

clean:
	rm -f *.rev
	rm -rf "MSL 3.2.1" "Modelica_LinearSystems2 2.3"
