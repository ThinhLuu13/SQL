USE QL_TRUONG
GO

-- Q1. Cho biết mã của các giáo viên có họ tên bắt đầu là “Nguyễn” và lương trên $2000 hoặc, giáo viên là trưởng bộ môn nhận chức sau năm 1995.

SELECT DISTINCT GV.MAGV, GV.HOTEN, GV.LUONG 
FROM GIAOVIEN GV , BOMON BM
WHERE (GV.HOTEN LIKE N'Nguyễn%' AND GV.LUONG >2000) OR (GV.MAGV = BM.TRUONGBM AND YEAR(BM.NGAYNHANCHUC) >1995) 

-- Q2. Với mỗi giáo viên, hãy cho biết thông tin của bộ môn mà họ đang làm việc.

SELECT GV.MAGV, GV.HOTEN, BM.* 
FROM GIAOVIEN GV
JOIN BOMON BM ON GV.MABM = BM.MABM

-- Q3. Cho biết tên giáo viên lớn tuổi nhất của bộ môn Hệ thống thông tin.

--C1:
SELECT GV.HOTEN, DATEDIFF(YEAR,GV.NGSINH,GETDATE()) AS N'Số tuổi' 
FROM GIAOVIEN GV, BOMON BM
WHERE GV.MABM = BM.MABM 
	AND BM.TENBM = N'Hệ thống thông tin' 
	AND DATEDIFF(YEAR,GV.NGSINH,GETDATE()) >= ALL(
													SELECT DATEDIFF(YEAR,GV1.NGSINH,GETDATE()) 
													FROM GIAOVIEN GV1, BOMON BM
													WHERE GV1.MABM = BM.MABM 
														AND BM.TENBM = N'Hệ thống thông tin'
												 )	
												 
--C2:
WITH TOP_AGE AS (
				SELECT GV.HOTEN, DATEDIFF(YEAR,GV.NGSINH,GETDATE()) AS AGE 
				FROM GIAOVIEN GV, BOMON BM
				WHERE GV.MABM = BM.MABM 
					AND BM.TENBM = N'Hệ thống thông tin'
				)
SELECT HOTEN, AGE
FROM TOP_AGE
WHERE TOP_AGE.AGE = (SELECT MAX(AGE) FROM TOP_AGE)
	
											
-- Q4.Cho biết họ tên giáo viên chủ nhiệm nhiều đề tài nhất.

--C1:
SELECT GV.HOTEN, COUNT(*) AS SL_CNDT
FROM GIAOVIEN GV , DETAI DT
WHERE GV.MAGV = DT.GVCNDT 
GROUP BY GV.HOTEN
HAVING COUNT(*) >= ALL(
						SELECT COUNT(*) 
						FROM GIAOVIEN GV , DETAI DT
						WHERE GV.MAGV = DT.GVCNDT 
						GROUP BY GV.HOTEN
						)

--C2:
WITH TOP_1 AS (
				SELECT GV.HOTEN, COUNT(*) AS COUNT_CNDT
				FROM GIAOVIEN GV, DETAI DT
				WHERE GV.MAGV = DT.GVCNDT
				GROUP BY GV.HOTEN
				)

SELECT HOTEN, COUNT_CNDT
FROM TOP_1
WHERE COUNT_CNDT = (SELECT MAX(COUNT_CNDT) FROM TOP_1)

-- Q5. Cho biết tên giáo viên và tên bộ môn của giáo viên tham gia nhiều đề tài nhất.

--C1:
SELECT GV.HOTEN, BM.TENBM, COUNT(TG.MADT) AS SL
FROM GIAOVIEN GV, BOMON BM, THAMGIADT TG
WHERE GV.MABM = BM.MABM AND GV.MAGV = TG.MAGV
GROUP BY GV.HOTEN, BM.TENBM
HAVING COUNT(TG.MADT) >= ALL( 
								SELECT COUNT(TG.MADT) AS SL
								FROM GIAOVIEN GV, BOMON BM, THAMGIADT TG
								WHERE GV.MABM = BM.MABM AND GV.MAGV = TG.MAGV
								GROUP BY GV.HOTEN, BM.TENBM
							)

--C2:
WITH TOP_DT AS (
	SELECT TOP(1) MAGV, COUNT(DISTINCT(MADT)) AS COUNT_DT
	FROM THAMGIADT TG
	GROUP BY MAGV
	ORDER BY COUNT_DT DESC)

SELECT HOTEN, TENBM
FROM GIAOVIEN GV
JOIN TOP_DT ON TOP_DT.MAGV = GV.MAGV
JOIN BOMON BM ON GV.MABM = BM.MABM

-- Q6. Cho biết tên đề tài nào mà được tất cả các giáo viên của bộ môn HTTT tham gia.

--C1:EXPECT
SELECT MADT, TENDT
FROM DETAI DT
WHERE NOT EXISTS(
				SELECT GV.MAGV
				FROM GIAOVIEN GV 
				WHERE GV.MABM = 'HTTT'
				
				EXCEPT 
				SELECT TG.MAGV
				FROM THAMGIADT TG
				WHERE TG.MADT = DT.MADT
				)
	AND EXISTS(
				SELECT GV.MAGV
				FROM GIAOVIEN GV 
				WHERE GV.MABM = 'HTTT')

--C2:COUNT
SELECT DT.MADT,DT.TENDT
FROM DETAI DT JOIN THAMGIADT TG ON TG.MADT = DT.MADT
			  JOIN GIAOVIEN GV ON TG.MAGV = GV.MAGV

WHERE GV.MABM = 'HTTT'
GROUP BY DT.MADT,DT.TENDT
HAVING COUNT(DISTINCT TG.MAGV) = (SELECT COUNT(*)
								   FROM GIAOVIEN GV 
								   WHERE GV.MABM = 'HTTT'
									)

-- Q7. Cho biết tên giáo viên nào đã tham gia tất cả các đề tài của do Trần Trà Hương làm chủ nhiệm.

--C1:
SELECT GV.MAGV, GV.HOTEN
FROM GIAOVIEN GV
WHERE NOT EXISTS( 
					SELECT DT.MADT
					FROM  DETAI DT, GIAOVIEN GV
					WHERE GV.HOTEN = N'Trần Trà Hương' AND DT.GVCNDT = GV.MAGV	
					
					EXCEPT
					SELECT TG.MADT
					FROM THAMGIADT TG
					WHERE TG.MAGV = GV.MAGV
				)
	AND EXISTS ( 
					SELECT DT.MADT
					FROM  DETAI DT, GIAOVIEN GV
					WHERE GV.HOTEN = N'Trần Trà Hương' AND DT.GVCNDT = GV.MAGV	
				)

--C2:
SELECT Q71.MAGV, GV.HOTEN
FROM(	
		SELECT TG.MAGV
		FROM GIAOVIEN GV , DETAI DT , THAMGIADT TG
		WHERE GV.HOTEN = N'Trần Trà Hương' AND DT.GVCNDT = GV.MAGV AND TG.MADT = DT.MADT 
		GROUP BY TG.MAGV, GV.HOTEN

		HAVING COUNT(DISTINCT TG.MADT) = (
											SELECT COUNT(*)
											FROM (
												SELECT DT.MADT
												FROM GIAOVIEN GV1 , DETAI DT
												WHERE GV1.HOTEN = N'Trần Trà Hương' AND DT.GVCNDT = GV1.MAGV
												) AS Q7
										)

	) AS Q71
JOIN GIAOVIEN GV ON Q71.MAGV = GV.MAGV						

-- Q8. Cho biết tên đề tài nào mà được tất cả các giáo viên của khoa CNTT tham gia.

SELECT DT.MADT, DT.TENDT
FROM DETAI DT
WHERE NOT EXISTS (
					SELECT GV.MAGV
					FROM GIAOVIEN GV, BOMON BM
					WHERE GV.MABM = BM.MABM AND BM.MAKHOA = 'CNTT'

					EXCEPT
					SELECT TG.MAGV
					FROM THAMGIADT TG
					WHERE TG.MADT = DT.MADT
				)
		AND EXISTS (
					SELECT GV.MAGV
					FROM GIAOVIEN GV, BOMON BM
					WHERE GV.MABM = BM.MABM AND BM.MAKHOA = 'CNTT'
					)

-- Q9. Cho biết tên đề tài nào mà được tất cả các giáo viên của khoa Sinh Học tham gia.

SELECT DT.MADT, DT.TENDT
FROM DETAI DT
WHERE NOT EXISTS (
					SELECT GV.MAGV
					FROM GIAOVIEN GV, BOMON BM, KHOA K
					WHERE GV.MABM = BM.MABM AND BM.MAKHOA = K.MAKHOA AND K.TENKHOA = N'Sinh Học'

					EXCEPT
					SELECT TG.MAGV
					FROM THAMGIADT TG
					WHERE TG.MADT = DT.MADT
				)
	AND EXISTS (
					SELECT GV.MAGV
					FROM GIAOVIEN GV, BOMON BM, KHOA K
					WHERE GV.MABM = BM.MABM AND BM.MAKHOA = K.MAKHOA AND K.TENKHOA = N'Sinh Học'
				)

-- Q10. Cho biết mã số, họ tên, tên bộ môn và tên người quản lý chuyên môn của giáo viên tham gia tất cả các đề tài thuộc chủ đề “Nghiên cứu phát triển”.
 
 SELECT Q10.MAGV, Q10.HOTEN, BM.TENBM, GV1.HOTEN AS TEN_GVQLCM
 FROM (
		 SELECT GV.MAGV, GV.HOTEN, GV.GVQLCM, GV.MABM
		 FROM GIAOVIEN GV
		 WHERE NOT EXISTS (
								SELECT DT.MADT
								FROM CHUDE CD, DETAI DT
								WHERE CD.TENCD =N'Nghiên cứu phát triển' AND CD.MACD = DT.MACD

								EXCEPT 
								SELECT TG.MADT
								FROM THAMGIADT TG
								WHERE TG.MAGV = GV.MAGV
							)
			AND EXISTS (
							SELECT DT.MADT
							FROM CHUDE CD, DETAI DT
							WHERE CD.TENCD =N'Nghiên cứu phát triển' AND CD.MACD = DT.MACD
						) 
		) AS Q10
JOIN BOMON BM ON Q10.MABM = BM.MABM
JOIN GIAOVIEN GV1 ON Q10.GVQLCM = GV1.MAGV

