#!/usr/bin/env bash
source "sharedFuncs.sh"

function main() {
    
    mkdir -p $SCR_PATH
    mkdir -p $CACHE_PATH
    
    setup_log "================| script executed |================"

    is64

    #make sure wine and winetricks package is already installed
    package_installed wine
    package_installed wine64
    package_installed md5sum
    package_installed winetricks

    RESOURCES_PATH="$SCR_PATH/resources"
    WINE_PREFIX="$SCR_PATH/prefix"
    
    #create new wine prefix for photoshop
    rmdir_if_exist $WINE_PREFIX
    
    #export necessary variable for wine
    export_var
    
    #config wine prefix and install mono and gecko automatic
    echo -e "\033[1;93mplease install mono and gecko packages then click on OK button, do not change Windows version from Windows 7\e[0m"
    winecfg 2> "$SCR_PATH/wine-error.log"
    if [ $? -eq 0 ];then
        show_message "prefix configured..."
        sleep 5
    else
        error "prefix config failed :("
    fi

    sleep 5
    if [ -f "$WINE_PREFIX/user.reg" ];then
        #add dark mod
        set_dark_mod
    else
        error "user.reg Not Found :("
    fi
   
    #create resources directory 
    rmdir_if_exist $RESOURCES_PATH

    # winetricks atmlib corefonts fontsmooth=rgb gdiplus vcrun2008 vcrun2010 vcrun2012 vcrun2013 vcrun2015 atmlib msxml3 msxml6 gdiplus
    winetricks atmlib fontsmooth=rgb vcrun2008 vcrun2010 vcrun2012 vcrun2013 atmlib msxml3 msxml6
    
    #install photoshop
    sleep 3
    install_photoshopSE
    sleep 5
    
    replacement

    if [ -d $RESOURCES_PATH ];then
        show_message "deleting resources folder"
        rm -rf $RESOURCES_PATH
    else
        error "resources folder Not Found"
    fi

    launcher
    show_message "\033[1;33mwhen you run photoshop for the first time it may take a while\e[0m"
    show_message "Almost finished..."
    sleep 30
}

function replacement() {
    local filename="replacement.tgz"
    local filelink="https://download856.mediafire.com/ogifl69iccxgRLD50nrJSfvYezVajr-ihtPMtQtTYXZIyi1tGCWZgWbwyJyyLfAvNfOEmT3Jv2tcq7rskfkFTHxhf4f5PihHq8imTdVX79flqFNk1tJMVEgdXIpEONZGKHGcPaQNrGbZ2HZAC2vwiql_fDwGNtuViJNHTdTlNEsOKPg/hu5jyfg2w6j6pxu/replacement.tgz"
    local filepath="$CACHE_PATH/$filename"
	
	# Verificar si el archivo ya existe en la carpeta destino
    if [ -f "$filepath" ]; then
        show_message "File already exists: $filepath. Overwriting..."
        rm "$filepath" || error "Error removing existing file: $filepath"
    fi

    wget -O "$filepath" "$filelink" || error "Error downloading $filename"
	#megadl --path="$filepath" "$filelink" || error "Error downloading $filename"

    mkdir "$RESOURCES_PATH/replacement"
    show_message "extract replacement component..."
    	
	# Descomprimir utilizando un tar diferente para manejar múltiples entradas gzip
    tar -xf "$filepath" -C "$RESOURCES_PATH/replacement" || error "Error extracting replacement files"

    local replacefiles=("IconResources.idx" "PSIconsHighRes.dat" "PSIconsLowRes.dat")
    local destpath="$WINE_PREFIX/drive_c/users/$USER/PhotoshopSE/Resources"
	    
    for f in "${replacefiles[@]}";do
        local sourcepath="$RESOURCES_PATH/replacement/$f"
		
     # Verificar si el archivo existe antes de copiarlo
        if [ -f "$sourcepath" ]; then
            cp -f "$sourcepath" "$destpath" || error "Can't copy replacement $f file..."
        else
            error "Replacement file $f not found."
        fi
    done

    show_message "replace component compeleted..."
    unset filename filemd5 filelink filepath
}

function install_photoshopSE() {
    local filename="photoshopCC-V19.1.6-2018x64.tgz"
    local filelink="https://download1591.mediafire.com/e2pa6l6b2ehgftInbViNlr64eqOjmHywY6AsaEDXeBi3yGr8iH8giewNN3mAFQlh6_znfqMLJZ8Mzw5clcd4UOX4f9TTDlDIRX3aA1hP4ozo10UsIFioFFnsPZmKLxsJ84MiPSuv8ZxpqvBkpGiKxZ8iv5n3b9U_u_yAj_OyCIhNFcU/q58wpcvf2l7gswp/photoshopCC-V19.1.6-2018x64.tgz"
    local filepath="$CACHE_PATH/$filename"
	
	# Verificar si el archivo ya existe en la carpeta destino
    if [ -f "$filepath" ]; then
        show_message "File already exists: $filepath. Overwriting..."
       rm "$filepath" || error "Error removing existing file: $filepath"
    fi
	
	wget -O "$filepath" "$filelink" || error "Error downloading $filename"
		
    mkdir "$RESOURCES_PATH/photoshopCC"
    show_message "extract photoshop..."
    tar -xzf "$filepath" -C "$RESOURCES_PATH/photoshopCC"

    echo "===============| photoshop CC v19 |===============" >> "$SCR_PATH/wine-error.log"
    show_message "install photoshop..."
    show_message "\033[1;33mPlease don't change default Destination Folder\e[0m"

    wine64 "$RESOURCES_PATH/photoshopCC/photoshop_cc.exe" &>> "$SCR_PATH/wine-error.log" || error "sorry something went wrong during photoshop installation"
    
    show_message "removing useless helper.exe plugin to avoid errors"
    rm "$WINE_PREFIX/drive_c/users/$USER/PhotoshopSE/Required/Plug-ins/Spaces/Adobe Spaces Helper.exe"

    notify-send "Photoshop CC" "photoshop installed successfully" -i "photoshop"
    show_message "photoshopCC V19 x64 installed..."
    unset filename filemd5 filelink filepath
}

check_arg $@
save_paths
main
