Това е сървърната част на проекта "DiaHelper" -> https://github.com/petyadamyanova/DiaHelperApp.git

Initial Setup
1. В Ubuntu server-а трябва да влезем като 'non-root' user и да инсталираме Swift ($ swiftly install latest).
2. След това трябва да инсталираме Vapor с помощта на Vapor Toolbox
2.1 Клонираме Vapor Toolbox репозиторията (git clone https://github.com/vapor/toolbox.git)
2.2 Трябва да изберем последната версия (git checkout 18.6.0)
2.3 Build-ваме Vapor (swift build -c release --disable-sandbox --enable-test-discovery sudo mv .build/release/vapor /usr/local/bin)
3. Създаваме проект - в случая клонираме тази репозитория (git clone https://github.com/petyadamyanova/VaporDiaHelper.git)
4. Влизаме в папката на проекта (cd VaporDiaHelper)
5. Изпълняваме командата - sudo ufw allow 8080
6. Стартираме сървъра (swift run App serve --hostname 0.0.0.0 --port 8080)
