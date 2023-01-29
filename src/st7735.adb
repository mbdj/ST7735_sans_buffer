package body ST7735 is



	----------------
	-- Initialize --
	----------------

	procedure Initialize  (LCD         :  in out ST7735;
								Choix_SPI   : in SPI.Choix_SPI;
								SPI_SCK     : in STM32.GPIO.GPIO_Point;
								SPI_MISO    : in STM32.GPIO.GPIO_Point;
								SPI_MOSI    : in STM32.GPIO.GPIO_Point;
								PIN_RS      : in out STM32.GPIO.GPIO_Point;
								PIN_RST     : in out STM32.GPIO.GPIO_Point;
								PIN_CS      : in out STM32.GPIO.GPIO_Point;
								Width       : in Natural := 128;  --  les spécifications du ST7735 sont données en orientation portrait
								Height      : in Natural := 160) is  --  les spécifications du ST7735 sont données en orientation portrait

		--  rajouter le paramètre landscape/portrait

		Max_Dim, Min_Dim : Natural;  --  dimensions max et min de l'écran

	begin

		--  Le driver ST7735 considère que l'écran est en format PORTRAIT
		--  C'est pourquoi ici on redresse les dimensions
		--  si jamais elles ont été passées à l'envers
		if (Width > Height) then
			Max_Dim := Width;
			Min_Dim := Height;
		else
			Max_Dim := Height;
			Min_Dim := Width;
		end if;


		Initialise_SPI (SPI      => Choix_SPI,
						SPI_SCK  => SPI_SCK,
						SPI_MISO => SPI_MISO,
						SPI_MOSI => SPI_MOSI,
						PIN_RS   => PIN_RS,
						PIN_RST  => PIN_RST,
						PIN_CS   => PIN_CS);

		--
		--  séquence d'initialisation de l'écran ST7735 décrite ici :
		--  https://github.com/AdaCore/Ada_Drivers_Library/blob/master/boards/OpenMV2/src/openmv-lcd_shield.adb
		--

		LCD.Initialize;

		LCD.Set_Memory_Data_Access
		  (	 Color_Order         => ST7735R.RGB_Order,
	  Vertical            => ST7735R.Vertical_Refresh_Top_Bottom,
	  Horizontal          => ST7735R.Horizontal_Refresh_Left_Right,
	  Row_Addr_Order      => ST7735R.Row_Address_Bottom_Top,
	  Column_Addr_Order   => ST7735R.Column_Address_Right_Left,
	  Row_Column_Exchange => False);

		LCD.Set_Pixel_Format ( ST7735R.Pixel_16bits);

		LCD.Set_Frame_Rate_Normal (RTN         => 16#01#,
									  Front_Porch => 16#2C#,
									  Back_Porch  => 16#2D#);

		LCD.Set_Frame_Rate_Idle (RTN         => 16#01#,
									Front_Porch => 16#2C#,
									Back_Porch  => 16#2D#);

		LCD.Set_Frame_Rate_Partial_Full (RTN_Part         => 16#01#,
											  Front_Porch_Part => 16#2C#,
											  Back_Porch_Part  => 16#2D#,
											  RTN_Full         => 16#01#,
											  Front_Porch_Full => 16#2C#,
											  Back_Porch_Full  => 16#2D#);

		LCD.Set_Inversion_Control (Normal       => ST7735R.Line_Inversion,
									  Idle         => ST7735R.Line_Inversion,
									  Full_Partial => ST7735R.Line_Inversion);

		LCD.Set_Power_Control_1 (AVDD => 2#101#,    --  5
									VRHP => 2#0_0010#, --  4.6
									VRHN => 2#0_0010#, --  -4.6
									MODE => 2#10#);    --  AUTO

		LCD.Set_Power_Control_2 (VGH25 => 2#11#,  --  2.4
									VGSEL => 2#01#,  --  3*AVDD
									VGHBT => 2#01#); --  -10

		LCD.Set_Power_Control_3 (16#0A#, 16#00#);
		LCD.Set_Power_Control_4 ( 16#8A#, 16#2A#);
		LCD.Set_Power_Control_5 ( 16#8A#, 16#EE#);
		LCD.Set_Vcom ( 16#E#);

		LCD.Set_Address (X_Start => 0,
						 X_End   => UInt16 (Min_Dim - 1),
						 Y_Start => 0,
						 Y_End   => UInt16 (Max_Dim - 1));

		LCD.Turn_On;

		LCD.Initialize_Layer (Layer  => 1,
								Mode   => HAL.Bitmap.RGB_565,
								X      => 0,
								Y      => 0 ,
								Width  => Min_Dim,
								Height => Max_Dim);


		--  initialisation de BitMap_Buffer
		--  voir https://github.com/AdaCore/Ada_Drivers_Library/blob/master/boards/OpenMV2/src/openmv-bitmap.adb


		--  if (Orientation = LANDSCAPE) then
		--  	LCD.Hidden_Buffer (Layer => 1).Actual_Width := Max_Dim;  --  inversion pour le mode landscape (sinon Width)
		--  	LCD.BitMap_Buffer.Actual_Height := Min_Dim;  --  inversion pour le mode landscape (sinon Height)
		--  	LCD.BitMap_Buffer.Currently_Swapped := True; --  inversion pour le mode landscape (sinon False)
		--  else
		--  	LCD.BitMap_Buffer.Actual_Width := Min_Dim;  --  inversion pour le mode landscape (sinon Width)
		--  	LCD.BitMap_Buffer.Actual_Height := Max_Dim;  --  inversion pour le mode landscape (sinon Height)
		--  	LCD.BitMap_Buffer.Currently_Swapped := False; --  inversion pour le mode landscape (sinon False)
		--  end if;
		--
		--  LCD.BitMap_Buffer.Actual_Color_Mode := HAL.Bitmap.RGB_565;


		--  LCD.BitMap_Buffer.Addr := LCD.Pixel_Data_BitMap_Buffer.all'Address;

	end Initialize;



	------------
	-- BitMap --
	------------

	function BitMap (LCD : in out ST7735) return HAL.Bitmap.Any_Bitmap_Buffer is
	begin
		return LCD.Hidden_Buffer (Layer => 1);
	end BitMap;



	-------------
	-- Display --
	-------------

	procedure Display (LCD : in out ST7735) is
	begin
		LCD.Update_Layer (Layer => 1);
	end Display;

end ST7735;
