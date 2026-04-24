SHELL := /bin/bash
CONFIG_FILE := .env.make

.PHONY: select_dir select_version select_world select_datapack create_datapack build show_config list_world_datapacks remove_datapack init

# -------------------------
# init - создать пустой конфиг если нет
# -------------------------
init:
	@touch $(CONFIG_FILE)

# -------------------------
# select_dir
# -------------------------
select_dir: init
	@read -p "Введите путь до .minecraft: " DIR; \
	DIR=$$(echo $$DIR | sed 's/["'\'']//g' | sed 's:/*$$::'); \
	echo "MC_DIR=$$DIR" > $(CONFIG_FILE); \
	echo "✅ MC_DIR = $$DIR"

# -------------------------
# select_version  
# -------------------------
select_version: init
	@DIR=$$(grep "^MC_DIR=" $(CONFIG_FILE) | cut -d= -f2-); \
	if [ -z "$$DIR" ]; then \
		echo "❌ Сначала запусти make select_dir"; exit 1; \
	fi; \
	if [ ! -d "$$DIR/versions" ]; then \
		echo "❌ Папка versions не найдена в $$DIR"; exit 1; \
	fi; \
	echo "Доступные версии:"; \
	ls -1 "$$DIR/versions" | grep -v "\.json$$" | nl; \
	read -p "Введи номер версии: " NUM; \
	VERSION=$$(ls -1 "$$DIR/versions" | grep -v "\.json$$" | sed -n "$${NUM}p"); \
	if [ -z "$$VERSION" ]; then \
		echo "❌ Неверный номер"; exit 1; \
	fi; \
	echo "MC_VERSION=$$VERSION" >> $(CONFIG_FILE); \
	echo "✅ MC_VERSION = $$VERSION"

# -------------------------
# select_world
# -------------------------
select_world: init
	@DIR=$$(grep "^MC_DIR=" $(CONFIG_FILE) | cut -d= -f2-); \
	if [ -z "$$DIR" ]; then \
		echo "❌ Сначала запусти make select_dir"; exit 1; \
	fi; \
	if [ ! -d "$$DIR/saves" ]; then \
		echo "❌ Папка saves не найдена в $$DIR"; exit 1; \
	fi; \
	echo "Доступные миры:"; \
	ls -1 "$$DIR/saves" | nl; \
	read -p "Введи номер мира: " NUM; \
	WORLD=$$(ls -1 "$$DIR/saves" | sed -n "$${NUM}p"); \
	if [ -z "$$WORLD" ]; then \
		echo "❌ Неверный номер"; exit 1; \
	fi; \
	echo "MC_WORLD=$$WORLD" >> $(CONFIG_FILE); \
	echo "✅ MC_WORLD = $$WORLD"

# -------------------------
# create_datapack
# -------------------------
create_datapack:
	@read -p "Введите имя датапака: " NAME; \
	mkdir -p "datapacks/$$NAME/data/$$NAME/functions"; \
	echo "{ \"pack\": { \"pack_format\": 15, \"description\": \"$$NAME\" } }" > "datapacks/$$NAME/pack.mcmeta"; \
	echo "✅ Создан datapack: datapacks/$$NAME"

# -------------------------
# select_datapack
# -------------------------
select_datapack: init
	@if [ ! -d "datapacks" ] || [ -z "$$(ls -A datapacks 2>/dev/null)" ]; then \
		echo "❌ Нет датапаков. Создай через make create_datapack"; exit 1; \
	fi; \
	echo "Доступные датапаки:"; \
	ls -1 datapacks | nl; \
	read -p "Введи номер датапака: " NUM; \
	DATAPACK=$$(ls -1 datapacks | sed -n "$${NUM}p"); \
	if [ -z "$$DATAPACK" ]; then \
		echo "❌ Неверный номер"; exit 1; \
	fi; \
	echo "DATAPACK=$$DATAPACK" >> $(CONFIG_FILE); \
	echo "✅ DATAPACK = $$DATAPACK"

# -------------------------
# build
# -------------------------
build: init
	@MC_DIR=$$(grep "^MC_DIR=" $(CONFIG_FILE) | cut -d= -f2-); \
	MC_WORLD=$$(grep "^MC_WORLD=" $(CONFIG_FILE) | cut -d= -f2-); \
	DATAPACK=$$(grep "^DATAPACK=" $(CONFIG_FILE) | cut -d= -f2-); \
	if [ -z "$$MC_DIR" ] || [ -z "$$MC_WORLD" ] || [ -z "$$DATAPACK" ]; then \
		echo "❌ Не всё настроено. Запусти:"; \
		echo "  make select_dir"; \
		echo "  make select_world"; \
		echo "  make select_datapack"; \
		exit 1; \
	fi; \
	TARGET="$$MC_DIR/saves/$$MC_WORLD/datapacks/$$DATAPACK"; \
	echo "📦 Копирую в $$TARGET"; \
	rm -rf "$$TARGET"; \
	mkdir -p "$$MC_DIR/saves/$$MC_WORLD/datapacks"; \
	cp -r "datapacks/$$DATAPACK" "$$TARGET"; \
	echo "✅ Готово"

# -------------------------
# list_world_datapacks
# -------------------------
list_world_datapacks: init
	@MC_DIR=$$(grep "^MC_DIR=" $(CONFIG_FILE) | cut -d= -f2-); \
	MC_WORLD=$$(grep "^MC_WORLD=" $(CONFIG_FILE) | cut -d= -f2-); \
	if [ -z "$$MC_DIR" ] || [ -z "$$MC_WORLD" ]; then \
		echo "❌ Сначала выполни make select_dir и make select_world"; exit 1; \
	fi; \
	DATAPACKS_DIR="$$MC_DIR/saves/$$MC_WORLD/datapacks"; \
	if [ ! -d "$$DATAPACKS_DIR" ]; then \
		echo "📁 В мире нет датапаков"; exit 0; \
	fi; \
	echo "📦 Датапаки в мире '$$MC_WORLD':"; \
	ls -1 "$$DATAPACKS_DIR" | nl || echo "   (нет датапаков)"

# -------------------------
# remove_datapack
# -------------------------
remove_datapack: init
	@MC_DIR=$$(grep "^MC_DIR=" $(CONFIG_FILE) | cut -d= -f2-); \
	MC_WORLD=$$(grep "^MC_WORLD=" $(CONFIG_FILE) | cut -d= -f2-); \
	if [ -z "$$MC_DIR" ] || [ -z "$$MC_WORLD" ]; then \
		echo "❌ Сначала выполни make select_dir и make select_world"; exit 1; \
	fi; \
	WORLD_DATAPACKS="$$MC_DIR/saves/$$MC_WORLD/datapacks"; \
	if [ ! -d "$$WORLD_DATAPACKS" ] || [ -z "$$(ls -A $$WORLD_DATAPACKS 2>/dev/null)" ]; then \
		echo "❌ В мире нет датапаков для удаления"; exit 1; \
	fi; \
	echo "Датапаки в мире '$$MC_WORLD':"; \
	ls -1 "$$WORLD_DATAPACKS" | nl; \
	read -p "Введи номер датапака для удаления: " NUM; \
	DATAPACK=$$(ls -1 "$$WORLD_DATAPACKS" | sed -n "$${NUM}p"); \
	if [ -z "$$DATAPACK" ]; then \
		echo "❌ Неверный номер"; exit 1; \
	fi; \
	echo "🗑️ Удаляю $$DATAPACK из мира"; \
	BACKUP_DIR="backups/$$MC_WORLD/$$(date +%Y%m%d_%H%M%S)"; \
	mkdir -p "$$BACKUP_DIR"; \
	cp -r "$$WORLD_DATAPACKS/$$DATAPACK" "$$BACKUP_DIR/"; \
	rm -rf "$$WORLD_DATAPACKS/$$DATAPACK"; \
	echo "✅ Датапак удалён (бэкап: $$BACKUP_DIR)"

# -------------------------
# show_config
# -------------------------
show_config:
	@if [ -f $(CONFIG_FILE) ]; then \
		echo "=== $(CONFIG_FILE) ==="; \
		cat $(CONFIG_FILE); \
	else \
		echo "❌ нет конфига"; \
	fi