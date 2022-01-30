
ACTION P1S1_ACT: 
	//���벽֮���л����趨ʱ��,��������Ϊ5s(�ɸ��ģ��������ŵ�λ��Һλ��ʱ��),���ڼ�鲽������ź�
	FOR i := 0 TO EDTP1S1_STEP_NUM DO
		IF EDTP1S1_ST[i] < T#5s THEN
			EDTP1S1_ST[i] := T#5s;
		END_IF;
		EDTP1S1_STEP[i].set_time := EDTP1S1_ST[i];
	END_FOR;
	
	//���̲���
	ProcessHandleFC(EDTP1S1,EDTP1S1_STEP[0],EDTP1S1_STEP_NUM);
	
	//object ���Զ��л�
	IF (EDTP1S1.status.mode <> 0) AND (NOT EDTP1S1.auto_mode_edge) THEN
		EDTP1S1.auto_mode_edge := TRUE;
		EDTP1S1.manual_mode_edge := FALSE;
		EDTR02.control.auto_operate := TRUE;
		EDTFQV0101.control.auto_operate := TRUE;
		EDTXV0102.control.auto_operate := TRUE;
	END_IF;
	
	IF (EDTP1S1.status.mode = 0) AND (NOT EDTP1S1.manual_mode_edge) THEN
		EDTP1S1.manual_mode_edge := TRUE;
		EDTP1S1.auto_mode_edge := FALSE;
		EDTR02.control.manual_operate := TRUE;
		EDTFQV0101.control.manual_operate := TRUE;
		EDTXV0102.control.manual_operate := TRUE;
	END_IF;
	
	//�����ź�ͣ��
	EDTP1S1.input.error_signal := (EDTR02.status.motor_status >= 2) OR (EDTFQV0101.status.valve_status >= 2) OR 
	(EDTXV0102.status.valve_status >= 2);
	
	//����ִ�ж���
	IF EDTP1S1.status.run_state = 1 THEN
		CASE EDTP1S1.status.run_step OF 
			0:
				//��ʼ�����
				IF NOT EDTP1S1_STEP[0].done THEN
					EDTR02.control.auto_operate := TRUE;
					EDTFQV0101.control.auto_operate := TRUE;
					EDTXV0102.control.auto_operate := TRUE;
					EDTP1S1_STEP[0].done := TRUE;
				END_IF;
			1:
				//�ص׷�
				EDTXV0102.input.auto_open_signal := FALSE;
				IF EDTXV0102.input.close_feedback_state THEN
					EDTP1S1_STEP[1].done := TRUE;
				END_IF;
			2:
				//�Ӷ�����ˮ
				LiquidTransfer_0(sp_time := DINT_TO_TIME(EDTP1S1_PARA_T1 * 1000),
				sp_accumulation := EDTP1S1_PARA_AC1,
				done := EDTP1S1_STEP[2].done,
				flowmeter := EDTFQIT1904);
				EDTFQV0101.input.auto_open_signal := LiquidTransfer_0.run;
			3:
				//��������
				EDTR02.input.auto_run_signal := TRUE;
				IF EDTR02.input.run_feedback THEN
					EDTP1S1_STEP[3].done := TRUE;
				END_IF;
			4:
				//�˹�Ͷ�ϣ���ɺ���ȷ��
			5:
				//�ܽ��ʱ
				TON_49.PT := DINT_TO_TIME(EDTP1S1_PARA_T2 * 60 * 1000);
				TON_49.IN := TRUE;
				IF TON_49.Q THEN
					TON_49.IN := FALSE;
					EDTP1S1_STEP[5].done := TRUE;
				END_IF;
				TON_49();
			6:
				//�۲��ܽ����
			7:
				//���׷����ؽ���
				EDTXV0102.input.auto_open_signal := TRUE;
				IF EDTXV0102.input.open_feedback_state THEN
					EDTR02.input.auto_run_signal := FALSE;
					IF NOT EDTR02.input.run_feedback THEN
						EDTP1S1_STEP[7].done := TRUE;
					END_IF;
				END_IF;
			8:
				//�۲츪�ڷ�����ɣ����ȷ��
			9:
				EDTXV0102.input.auto_open_signal := FALSE;
				IF EDTXV0102.input.close_feedback_state THEN
					EDTP1S1_STEP[9].done := TRUE;
				END_IF;
			10:
				//�ֶ�ͨ��������������
		END_CASE;
	END_IF;
	
	//�˹�ȷ�ϲ������
	IF (EDTP1S1.status.run_state) AND (NOT EDTP1S1_STEP[EDTP1S1.status.run_step].done AND ((EDTP1S1.status.run_step = 4) OR (EDTP1S1.status.run_step = 6) 
		OR (EDTP1S1.status.run_step = 8) OR (EDTP1S1.status.run_step = 10))) THEN
		EDTP1S1.status.confirm_enable := TRUE;
	ELSE
		EDTP1S1.status.confirm_enable := FALSE;
	END_IF;
END_ACTION