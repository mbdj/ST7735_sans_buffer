with HAL.Bitmap;
with HAL.Time;
with ST7735R;
with HAL; use HAL;
with SPI; use SPI;
with HAL.SPI; use HAL.SPI;
with HAL.GPIO; use HAL.GPIO;


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

	type Type_Orientation is (LANDSCAPE, PORTRAIT);

		type ST7735
	  (Port                : not null Any_SPI_Port;
	 CS                  : not null Any_GPIO_Point;
	 RS                  : not null Any_GPIO_Point;
	 RST                 : not null Any_GPIO_Point;
	 Time                : not null HAL.Time.Any_Delays;
	 Choix_SPI           :  SPI.Choix_SPI;
	 SPI_SCK             :  not null Any_GPIO_Point;
	 SPI_MISO            :  not null Any_GPIO_Point;
	 SPI_MOSI            :  not null Any_GPIO_Point;
	 Width               :  Natural;
	 Height              :  Natural;
	 	 Orientation         :  Type_Orientation;
	 Color_Correction    :  Boolean)
	is limited new ST7735R.ST7735R_Screen with private;

	--  initialisation de l'écran et du buffer
	procedure Initialize (LCD : in out ST7735);

	--  retourne la bitmap sur laquelle on peut dessiner
	--  pour écrire : utiliser les primitives du package Bitmapped_Drawing / Soft_Drawing_Bitmap
	--  pour dessiner : utiliser le package HAL.Bitmap
	function BitMap (LCD : in out ST7735) return HAL.Bitmap.Any_Bitmap_Buffer;

	--  après avoir dessiner sur la bitmap il faut appeler Display pour afficher sur l'écran physique
	procedure Display (LCD : in out ST7735);

private

	--  type ST7735_Buffering is record
	type ST7735
	  (Port                : not null Any_SPI_Port;
	 CS                  : not null Any_GPIO_Point;
	 RS                  : not null Any_GPIO_Point;
	 RST                 : not null Any_GPIO_Point;
	 Time                : not null HAL.Time.Any_Delays;
	 Choix_SPI           :  SPI.Choix_SPI;
	 SPI_SCK             :  not null Any_GPIO_Point;
	 SPI_MISO            :  not null Any_GPIO_Point;
	 SPI_MOSI            :  not null Any_GPIO_Point;
	 Width               :  Natural;
	 Height              :  Natural;
	 	 Orientation         :  Type_Orientation;
	 Color_Correction    :  Boolean)
	is limited new ST7735R.ST7735R_Screen
	  (Port         => Port,
	 CS           => CS,
	 RS           => RS,
	 RST          => RST,
	 Time         => Time) with null record;

end ST7735;
