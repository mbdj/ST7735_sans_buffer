with STM32.GPIO;

package body ST7735 is

	----------------
	-- Initialize --
	----------------

	procedure Initialize  (LCD : in out ST7735) is
	--  rajouter le paramètre landscape/portrait

		Max_Dim, Min_Dim : Natural;

	begin

		if (LCD.Width > LCD.Height) then
			Max_Dim := LCD.Width;
			Min_Dim := LCD.Height;
		else
			Max_Dim := LCD.Height;
			Min_Dim := LCD.Width;
		end if;


		Initialise_SPI (SPI      => LCD.Choix_SPI,
						SPI_SCK  => STM32.GPIO.GPIO_Point (LCD.SPI_SCK.all),
						SPI_MISO => STM32.GPIO.GPIO_Point (LCD.SPI_MISO.all),
						SPI_MOSI => STM32.GPIO.GPIO_Point (LCD.SPI_MOSI.all),
						PIN_RS   => STM32.GPIO.GPIO_Point (LCD.RS.all),
						PIN_RST  => STM32.GPIO.GPIO_Point (LCD.RST.all),
						PIN_CS   => STM32.GPIO.GPIO_Point (LCD.CS.all));

		--
		--  séquence d'initialisation de l'écran ST7735 décrite ici :
		--  https://github.com/AdaCore/Ada_Drivers_Library/blob/master/boards/OpenMV2/src/openmv-lcd_shield.adb
		--

		ST7735R.Initialize (LCD => ST7735R.ST7735R_Screen (LCD));


		LCD.Set_Memory_Data_Access
		  (	 Color_Order         => (if LCD.Color_Correction then ST7735R.BGR_Order else ST7735R.RGB_Order),
	  Vertical            => ST7735R.Vertical_Refresh_Top_Bottom,
	  Horizontal          => ST7735R.Horizontal_Refresh_Left_Right,
	  Row_Addr_Order      => ST7735R.Row_Address_Bottom_Top,
	  Column_Addr_Order   => (if LCD.Orientation = LANDSCAPE then ST7735R.Column_Address_Left_Right else ST7735R.Column_Address_Right_Left),
	  Row_Column_Exchange => (if LCD.Orientation = LANDSCAPE then True else False));

		LCD.Set_Pixel_Format (ST7735R.Pixel_16bits);

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

		if LCD.Orientation = PORTRAIT then
		LCD.Set_Address (X_Start => 0,
						 X_End   => UInt16 (Min_Dim - 1),
						 Y_Start => 0,
						 Y_End   => UInt16 (Max_Dim - 1));
		else
			LCD.Set_Address (X_Start => 0,
						  X_End   => UInt16 (Max_Dim - 1),
						  Y_Start => 0,
						  Y_End   => UInt16 (Min_Dim - 1));
			end if;

		if LCD.Color_Correction then
			LCD.Display_Inversion_On;
		end if;

		LCD.Turn_On;

		if LCD.Orientation = PORTRAIT then
			LCD.Initialize_Layer (Layer  => 1,
								 Mode   => HAL.Bitmap.RGB_565,
								 X      => 0,
								 Y      => 0 ,
								 Width  => Min_Dim,
								 Height => Max_Dim);
		else
			LCD.Initialize_Layer (Layer  => 1,
								 Mode   => HAL.Bitmap.RGB_565,
								 X      => 0,
								 Y      => 0 ,
								 Width  => Max_Dim,
								 Height => Min_Dim);
		end if;

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
