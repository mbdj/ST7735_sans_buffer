--
-- Mehdi 28/01/2023 --
--
--  Test de l'écran ST7735
--

with Last_Chance_Handler;
pragma Unreferenced (Last_Chance_Handler);
--  The "last chance handler" is the user-defined routine that is called when
--  an exception is propagated. We need it in the executable, therefore it
--  must be somewhere in the closure of the context clauses.


with Ada.Real_Time; use Ada.Real_Time;
with SPI;

with ST7735; use ST7735;

with Bitmapped_Drawing;
with BMP_Fonts;

with HAL;
with HAL.Bitmap;

with STM32.Board;
with STM32.Device;

with Ravenscar_Time;


procedure Testst7735 is

	----------------------------------------------------
	function Min (A, B : in Natural) return Natural is (if A > B then B else A);
	function Max (A, B : in Natural) return Natural is (if A > B then A else B);
	----------------------------------------------------

	Width       :  constant Natural := 160;
	Height      :  constant Natural := 128;
	Orientation : constant Type_Orientation := landscape;


	--  dimensions de l'écran ST7735
	Period       : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds (50);
	Next_Release : Ada.Real_Time.Time := Ada.Real_Time.Clock;

	Ecran_ST7735 : ST7735.ST7735 (Port             => STM32.Device.SPI_2'Access,
										 CS               => STM32.Device.PB4'Access,
										 RS               => STM32.Device.PB10'Access,
										 RST              => STM32.Device.PA8'Access,
										 Time             => Ravenscar_Time.Delays,
										 Choix_SPI        => SPI.SPI2,
										 SPI_SCK          => STM32.Device.PB13'Access,  -- à raccorder à SCK ou SCL       (SPI1 : PA5 ; SPI2 : PB13)
										 SPI_MISO         => STM32.Device.PB14'Access,  -- pas utilisé sur l'écran ST7735 (SPI1 : PA7 ; SPI2 : PB14)
										 SPI_MOSI         => STM32.Device.PB15'Access,  -- à raccorder à SDA              (SPI1 : PA7 ; SPI2 : PB15)
										 Width            => 128,              -- backlight (LEDA ou BLK) doit être raccordé à +3.3V ou +5V
										 Height           => 160,
										 Orientation      => Orientation,
										 Color_Correction => False);

	Compteur : Natural := 0; --  compteur affiché sur le ST7735
	PosY     : Natural := 20; --  position où on affiche le compteur

begin
	--  Initialiser l'écran TFT ST7735
	Ecran_ST7735.Initialize;

	--  initialiser la led utilisateur verte
	STM32.Board.Initialize_LEDs; -- utiliser uniquement avec le ST7735 sur SPI2 car les pins PA5,PA6,PA7 de SPI1 sont utilisées pour les LED
	STM32.Board.Turn_On (STM32.Board.Green_LED);

	--  \u00e9criture sur le ST7735
	--  nb : il faut redessiner toute l'image \u00e0 chaque fois
	--  il faut dessiner dans la BitMap puis afficher sur l'\u00e9cran physique avec Display
	Ecran_ST7735.BitMap.Set_Source (ARGB => HAL.Bitmap.Red);
	Ecran_ST7735.BitMap.Fill;
	Bitmapped_Drawing.Draw_String (Ecran_ST7735.BitMap.all,
										  Start      => (0, 0),
										  Msg        => ("ST7735"),
										  Font       => BMP_Fonts.Font8x8,
										  Foreground => HAL.Bitmap.Red,
										  Background => HAL.Bitmap.Green);

	Bitmapped_Drawing.Draw_String (Ecran_ST7735.BitMap.all,
										  Start      => (0, PosY),
										  Msg        => (Compteur'Image),
										  Font       => BMP_Fonts.Font12x12,
										  Foreground => HAL.Bitmap.White,
										  Background => HAL.Bitmap.Blue);
	loop
		STM32.Board.Toggle (STM32.Board.Green_LED);

		declare
			Hauteur : constant Integer := (if Orientation = LANDSCAPE then Min (Width, Height) else Max (Width, Height));
		begin
			PosY := (if PosY > Hauteur then 0 else PosY + 1);
		end;

		Ecran_ST7735.BitMap.Set_Source (ARGB => HAL.Bitmap.Cyan);

		Bitmapped_Drawing.Draw_String (Ecran_ST7735.BitMap.all,
											Start      => (0, PosY),
											Msg        => (Compteur'Image),
											Font       => BMP_Fonts.Font12x12,
											Foreground => HAL.Bitmap.White,
											Background => HAL.Bitmap.Blue);

		--  affiche sur l'écran physique ce qui a été dessiné sur la bitmap
		Ecran_ST7735.Display;

		Compteur := Compteur + 1 ;

		Next_Release := Next_Release + Period;
		delay until Next_Release;

	end loop;
end Testst7735;
