# Common rules: run an R script and stamp a .done file
%.done: %.R
	@echo "Running $< ..."
	Rscript $<
	@touch $@


#
# cubes
#
CUBE_SCRIPTS := $(sort $(wildcard analysis/cubes/*.R))
CUBE_DONE    := $(CUBE_SCRIPTS:.R=.done)

.PHONY: cubes cubes-clean
.NOTPARALLEL: cubes
cubes: $(CUBE_DONE)
cubes-clean:
	@rm -f $(CUBE_DONE)


#
# mosaics
#
MOSAIC_SCRIPTS := $(sort $(wildcard analysis/mosaics/*.R))
MOSAIC_DONE    := $(MOSAIC_SCRIPTS:.R=.done)

.PHONY: mosaics mosaics-clean
.NOTPARALLEL: mosaics
mosaics: $(MOSAIC_DONE)
mosaics-clean:
	@rm -f $(MOSAIC_DONE)


#
# models
#
MODEL_SCRIPTS := $(sort $(wildcard analysis/models/train-*.R))
MODEL_DONE    := $(MODEL_SCRIPTS:.R=.done)

.PHONY: models models-clean
.NOTPARALLEL: models
models: $(MODEL_DONE)
models-clean:
	@rm -f $(MODEL_DONE)


#
# classifications
#
CLASS_SCRIPTS := $(sort $(wildcard analysis/classifications/classify-*.R))
CLASS_DONE    := $(CLASS_SCRIPTS:.R=.done)

.PHONY: classifications classifications-clean
.NOTPARALLEL: classifications
classifications: $(CLASS_DONE)
classifications-clean:
	@rm -f $(CLASS_DONE)


#
# masks
#
MASK_YEARLY   := $(sort $(wildcard analysis/masks/mask-20*.R))
MASK_EXTRA    := analysis/masks/mask-temporal-allyears.R
MASK_SCRIPTS  := $(MASK_YEARLY) $(MASK_EXTRA)
MASK_DONE     := $(MASK_SCRIPTS:.R=.done)

.PHONY: masks masks-clean
.NOTPARALLEL: masks
masks: $(MASK_DONE)
masks-clean:
	@rm -f $(MASK_DONE)


#
# all / clean convenience targets
#
.PHONY: all clean
all: masks cubes classifications models mosaics
clean: masks-clean cubes-clean classifications-clean models-clean mosaics-clean
