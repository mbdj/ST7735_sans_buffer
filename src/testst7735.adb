with HAL.SPI;

--
-- Mehdi 04/01/2023 --
--
--  Test de l'�cran ST7735
--

with Last_Chance_Handler;
pragma Unreferenced (Last_Chance_Handler);
--  The "last chance handler" is the user-defined routine that is called when
--  an exception is propagated. We need it in the executable, therefore it
--  must be somewhere in the closure of the context clauses.

with STM32.Board;

with Ada.Real_Time; use Ada.Real_Time;



--  �cran ST7735
--  with ST7735R.RAM_Framebuffer;
with ST7735R;


with Bitmapped_Drawing;
--  with BMP_Fonts;
with HAL.Bitmap;

with STM32.Device;
with STM32.GPIO;
with STM32.SPI;


with Ravenscar_Time;
with BMP_Fonts;




procedure Testst7735 is


	--
	--  s�quence d'initialisation de l'�cran ST7735 d�crite ici :
	--  https://github.com/AdaCore/Ada_Drivers_Library/blob/master/boards/OpenMV2/src/openmv-lcd_shield.adb
	--
	procedure Initialise (Ecran : in out ST7735R.ST7735R_Screen) is
	begin
		Ecran.Initialize;

		Ecran.Set_Memory_Data_Access
		  (	 Color_Order         => ST7735R.RGB_Order,
	  Vertical            => ST7735R.Vertical_Refresh_Top_Bottom,
	  Horizontal          => ST7735R.Horizontal_Refresh_Left_Right,
	  Row_Addr_Order      => ST7735R.Row_Address_Bottom_Top,
	  Column_Addr_Order   => ST7735R.Column_Address_Right_Left,
	  Row_Column_Exchange => False);

		Ecran.Set_Pixel_Format ( ST7735R.Pixel_16bits);

		Ecran.Set_Frame_Rate_Normal (RTN         => 16#01#,
										 Front_Porch => 16#2C#,
										 Back_Porch  => 16#2D#);

		Ecran.Set_Frame_Rate_Idle (RTN         => 16#01#,
									  Front_Porch => 16#2C#,
									  Back_Porch  => 16#2D#);

		Ecran.Set_Frame_Rate_Partial_Full (RTN_Part         => 16#01#,
												 Front_Porch_Part => 16#2C#,
												 Back_Porch_Part  => 16#2D#,
												 RTN_Full         => 16#01#,
												 Front_Porch_Full => 16#2C#,
												 Back_Porch_Full  => 16#2D#);

		Ecran.Set_Inversion_Control (Normal       => ST7735R.Line_Inversion,
										 Idle         => ST7735R.Line_Inversion,
										 Full_Partial => ST7735R.Line_Inversion);

		Ecran.Set_Power_Control_1 (AVDD => 2#101#,    --  5
									  VRHP => 2#0_0010#, --  4.6
									  VRHN => 2#0_0010#, --  -4.6
									  MODE => 2#10#);    --  AUTO

		Ecran.Set_Power_Control_2 (VGH25 => 2#11#,  --  2.4
									  VGSEL => 2#01#,  --  3*AVDD
									  VGHBT => 2#01#); --  -10

		Ecran.Set_Power_Control_3 (16#0A#, 16#00#);
		Ecran.Set_Power_Control_4 ( 16#8A#, 16#2A#);
		Ecran.Set_Power_Control_5 ( 16#8A#, 16#EE#);
		Ecran.Set_Vcom ( 16#E#);

		Ecran.Set_Address (X_Start => 0,
							X_End   => 127,
							Y_Start => 0,
							Y_End   => 159);

		Ecran.Turn_On;

		Ecran.Initialize_Layer (Layer  => 1,
											Mode   => HAL.Bitmap.RGB_565,
											X      => 0,
											Y      => 0 ,
											Width  => 128,
											Height => 160);
	end Initialise;

	Period       : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds (100);
	Next_Release : Ada.Real_Time.Time := Ada.Real_Time.Clock;



	--  Initialisation de l'�cran ST7735 en SPI (sur SPI 1)
	--  SPI1_SCK : PA5
	--  SPI1_MISO : PA6 = pas utilis�
	--  SPI1_MOSI (-> SDA) : PA7
	--  CS, RS, RST : � fixer comme on veut
	--  LEDA (pin 8 du ST7735) : connect� sur VCC (3.3V)

	SPI1_SCK  : STM32.GPIO.GPIO_Point renames STM32.Device.PA5;
	SPI1_MISO : STM32.GPIO.GPIO_Point renames STM32.Device.PA6;
	SPI1_MOSI : STM32.GPIO.GPIO_Point renames STM32.Device.PA7;
	--  SPI1_NSS  : STM32.GPIO.GPIO_Point renames STM32.Device.PB4; -- CS (chip select)

	ST7735_RS :  STM32.GPIO.GPIO_Point renames STM32.Device.PB10;  -- resgister select
	ST7735_RST  : STM32.GPIO.GPIO_Point renames STM32.Device.PA8;  -- reset
	ST7735_CS :  STM32.GPIO.GPIO_Point renames STM32.Device.PB4; -- chip select = SPI2_NSS

	ST7735_CS_RS_RST  : constant STM32.GPIO.GPIO_Points := (ST7735_RS, ST7735_RST, ST7735_CS);
	SPI1_Points : constant STM32.GPIO.GPIO_Points := (SPI1_SCK, SPI1_MISO, SPI1_MOSI); --, SPI1_NSS);

	SPI_Conf  : STM32.SPI.SPI_Configuration;
	GPIO_Conf : STM32.GPIO.GPIO_Port_Configuration;

	Ecran_ST7735 : ST7735R.ST7735R_Screen (Port   => STM32.Device.SPI_1'Access,
													 CS     => ST7735_CS'Access,
													 RS     => ST7735_RS'Access,
													 RST    => ST7735_RST'Access,
													 Time   => Ravenscar_Time.Delays);

	BM           : HAL.Bitmap.Any_Bitmap_Buffer := Ecran_St7735.Hidden_Buffer (Layer => 1); --  bitmap du ST7735 dans laquelle dessiner

	Compteur     : Integer := 0;

begin

	--  initialiser SPI 1
	--  voir https://github.com/AdaCore/Ada_Drivers_Library/blob/5ffdf12bec720aea12467229bb5862c465bf0333/boards/OpenMV2/src/openmv.adb#L140

	STM32.Device.Enable_Clock (SPI1_Points);

	GPIO_Conf := (Mode           => STM32.GPIO.Mode_AF,
					AF             => STM32.Device.GPIO_AF_SPI1_5,
					Resistors      => STM32.GPIO.Pull_Down, --  SPI low polarity
					AF_Speed       => STM32.GPIO.Speed_100MHz,
					AF_Output_Type => STM32.GPIO.Push_Pull);

	STM32.GPIO.Configure_IO (SPI1_Points, GPIO_Conf);


	STM32.Device.Enable_Clock (STM32.Device.SPI_1);

	STM32.Device.SPI_1.Disable;

	SPI_Conf.Direction           := STM32.SPI.D2Lines_FullDuplex;
	SPI_Conf.Mode                := STM32.SPI.Master;
	SPI_Conf.Data_Size           := HAL.SPI.Data_Size_8b;
	SPI_Conf.Clock_Polarity      := STM32.SPI.Low;
	SPI_Conf.Clock_Phase         := STM32.SPI.P1Edge;
	SPI_Conf.Slave_Management    := STM32.SPI.Software_Managed;
	SPI_Conf.Baud_Rate_Prescaler := STM32.SPI.BRP_2;
	SPI_Conf.First_Bit           := STM32.SPI.MSB;
	SPI_Conf.CRC_Poly            := 7;

	STM32.Device.SPI_1.Configure (SPI_Conf);

	STM32.Device.SPI_1.Enable;

	STM32.Device.Enable_Clock (ST7735_CS_RS_RST);

	GPIO_Conf := (Mode        => STM32.GPIO.Mode_Out,
					Output_Type => STM32.GPIO.Push_Pull,
					Speed       => STM32.GPIO.Speed_100MHz,
					Resistors   => STM32.GPIO.Floating);

	STM32.GPIO.Configure_IO (ST7735_CS_RS_RST, GPIO_Conf);

	--  Initialiser l'�cran TFT ST7735
	Initialise (Ecran_ST7735);


	--  Remplir L'�cran Avec Une Couleur
	--  for X in 0 .. 128 loop
	--  	for Y in 0 .. 160 loop
	--  		Ecran_ST7735.Set_Pixel (X => HAL.UInt16 (X), Y => HAL.UInt16 (Y), Color => 0);
	--  	end loop;
	--  end loop;


	Ecran_ST7735.Update_Layer (Layer => 1);

	-- Set_Source fixe la couleur de trac�
	BM.Set_Source (ARGB => HAL.Bitmap.Gold);
	BM.Fill;

	BM.Set_Source (ARGB => HAL.Bitmap.Cyan);
	BM.Draw_Circle (Center => (X => 50, Y => 50) , Radius =>  40);

	BM.Set_Source (ARGB => HAL.Bitmap.Violet);
	BM.Draw_Line (Start => (20, 20), Stop => (100, 80), Thickness => 3);

	Bitmapped_Drawing.Draw_String (BM.all,
										  Start      => (50, 50),
										  Msg        => ("TEST"),
										  Font       => BMP_Fonts.Font8x8,
										  Foreground => HAL.Bitmap.Red,
										  Background => HAL.Bitmap.White);
	--  Ecran_ST7735.Update_Layer (Layer => 1);


	--  tracer un trait
	--  for Y in 10 .. 100 loop
	--  	Ecran_ST7735.Set_Pixel (X => 20, Y => HAL.UInt16 (Y), Color => 31);  -- Color au format RGB 565 : R sur 5bits G sur 6 bits B sur 5 bits
	--  end loop;
	--
	--  Ecran_ST7735.Update_Layer (Layer => 1);

	--  initialiser la led utilisateur verte
	--  STM32.Board.Initialize_LEDs; -- l'initialisation des LED emp�che l'affichage sur ST7735 car les pins PA5,PA6,PA7 de SPI1 sont utilis�es pour les LED
	--  STM32.Board.Turn_On (STM32.Board.Green_LED);



	--  Ecran_ST7735.Update_Layer (Layer => 1);

	--  STM32.Board.Turn_Off (STM32.Board.Green_LED);

	loop
		--  STM32.Board.Toggle (STM32.Board.Green_LED);

		--  �criture sur le ST7735
		Bitmapped_Drawing.Draw_String (BM.all,
											Start      => (30, 30),
											Msg        => (Compteur'Image),
											Font       => BMP_Fonts.Font12x12,
											Foreground => HAL.Bitmap.White,
											Background => HAL.Bitmap.Blue);
		Compteur := Compteur + 1 ;

		Next_Release := Next_Release + Period;
		delay until Next_Release;

	end loop;

end Testst7735;
