with HAL.Bitmap;
with ST7735R;
with HAL; use HAL;
with STM32.GPIO;
with SPI; use SPI;


package ST7735 is
--  driver pour un écran ST7735 avec buffer
--
--  principe :
--   1- Initialiser l'écran avec Initialise()
--   2- Dessiner dans le buffer accessible par la fonction BitMap()
--   3- Afficher sur l'écran physique avec Display
--
--  Il faut refaire le dessin complet avant chaque Display
--

	type ST7735 is limited new ST7735R.ST7735R_Screen with private;

	type Type_Orientation is (LANDSCAPE, PORTRAIT);

	--  initialisation de l'écran et du buffer
	procedure Initialize (LCD            : in out ST7735;
							  Choix_SPI      : in SPI.Choix_SPI;
							  SPI_SCK        : in STM32.GPIO.GPIO_Point;
							  SPI_MISO       : in STM32.GPIO.GPIO_Point;
							  SPI_MOSI       : in STM32.GPIO.GPIO_Point;
							  PIN_RS         : in out STM32.GPIO.GPIO_Point;
							  PIN_RST        : in out STM32.GPIO.GPIO_Point;
							  PIN_CS         : in out STM32.GPIO.GPIO_Point;
							  Width          : in Natural := 128;  --  les spécifications du ST7735 sont données en orientation portrait
							  Height         : in Natural := 160);  --  les spécifications du ST7735 sont données en orientation portrait

	--  retourne la bitmap sur laquelle on peut dessiner
	--  pour écrire : utiliser les primitives du package Bitmapped_Drawing / Soft_Drawing_Bitmap
	--  pour dessiner : utiliser le package HAL.Bitmap
	function BitMap (LCD : in out ST7735) return HAL.Bitmap.Any_Bitmap_Buffer;

	--  après avoir dessiner sur la bitmap il faut appeler Display pour afficher sur l'écran physique
	procedure Display (LCD : in out ST7735);

private

	--  type ST7735_Buffering is record
	type ST7735 is limited new ST7735R.ST7735R_Screen with record
		Choix_SPI    :  SPI.Choix_SPI;
		SPI_SCK      :  STM32.GPIO.GPIO_Point;
		SPI_MISO     :  STM32.GPIO.GPIO_Point;
		SPI_MOSI     :  STM32.GPIO.GPIO_Point;
		PIN_RS       :  STM32.GPIO.GPIO_Point;
		PIN_RST      :  STM32.GPIO.GPIO_Point;
		PIN_CS       :  STM32.GPIO.GPIO_Point;
		Width        :  Natural := 128;
		Height       :  Natural := 160;
	end record;

end ST7735;
