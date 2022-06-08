LOCAL_PATH := $(call my-dir)

#----------------------------------------------------------------------
# Radio image
#----------------------------------------------------------------------
ifeq ($(ADD_RADIO_FILES), true)
$(call add-radio-file,images/abl.img)
$(call add-radio-file,images/aop.img)
$(call add-radio-file,images/bluetooth.img)
$(call add-radio-file,images/cpucp.img)
$(call add-radio-file,images/devcfg.img)
$(call add-radio-file,images/dsp.img)
$(call add-radio-file,images/featenabler.img)
$(call add-radio-file,images/hyp.img)
$(call add-radio-file,images/imagefv.img)
$(call add-radio-file,images/keymaster.img)
$(call add-radio-file,images/modem.img)
$(call add-radio-file,images/multiimgoem.img)
$(call add-radio-file,images/oplus_sec.img)
$(call add-radio-file,images/oplusstanvbk.img)
$(call add-radio-file,images/qupfw.img)
$(call add-radio-file,images/qweslicstore.img)
$(call add-radio-file,images/shrm.img)
$(call add-radio-file,images/splash.img)
$(call add-radio-file,images/tz.img)
$(call add-radio-file,images/uefisecapp.img)
$(call add-radio-file,images/vm-bootsys.img)
$(call add-radio-file,images/xbl.img)
$(call add-radio-file,images/xbl_config.img)
# Android 12 images.
$(call add-radio-file,images/engineering_cdt.img)
endif