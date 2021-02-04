#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
//-------------------------------------------------------------------
/*/{Protheus.doc} REPP12SIMP
description: WebServices de replica para o P12 Simplificado
@author  Ricardo Junior
@since   26/01/2021
@version 1.0
/*/
//-------------------------------------------------------------------
WSRESTFUL REPP12SIMP DESCRIPTION "Metodo disponível para replica de cadastros do P12 Full para o P12 Simplificado."

	WSDATA cTabela AS CHARACTER
	WSDATA cCodigo AS CHARACTER

	WSMETHOD POST TABLE DESCRIPTION "Método POST." PATH "/"

END WSRESTFUL

WSMETHOD POST TABLE WSSERVICE REPP12SIMP
	Local aArea := GetArea()
	private cMessage := ""

	cMessage := U_P12SIMP01(::GetContent())

	::setResponse(cMessage)
	RestArea(aArea)
Return .T.
//-------------------------------------------------------------------
/*/{Protheus.doc} P12SIM01
description: Monta array para executar reclock
@author  Ricardo Junior
@since   26/01/2021
@version 1.0
/*/
//-------------------------------------------------------------------
user function P12SIMP01(cBody)

	default cBody := ""

	oJson := JsonObject():New()
	ret := oJson:FromJson(cBody)

	if ValType(ret) == "C"
		conout("Falha ao transformar texto em objeto json. Erro: " + ret)
		return
	endif

Return u_PrintJson(oJson)

//-------------------------------------------------------------------
/*/{Protheus.doc} PrintJson
description: Função para montar a estrutura com os dados.
@author  Ricardo Junior
@since   26/01/2021
@version 1.0
/*/
//-------------------------------------------------------------------
user function PrintJson(jsonObj)
	local i, j
	local names
	local lenJson
	local item
	Local aDados := {}
	local lInc	:= .T.
	local nX	:= 00
	local lDeletado := .F.

	private oError := ErrorBlock({|e| cMessage := '{"status": "ERROR", "message": '+chr(10)+ e:Description +'}' })

	lenJson := len(jsonObj)

	if lenJson > 0
		for i := 1 to lenJson
			u_PrintJson(jsonObj[i])
		next
	else
		names := jsonObj:GetNames()
		cTabela := getTabela(names)
		for i := 1 to len(names)
			//conout("Label - " + names[i])
			item := jsonObj[names[i]]
			if ValType(item) == "C"
				//conout( names[i] + " = " + cvaltochar(jsonObj[names[i]]))
				if Upper(names[i]) $ "D_E_L_E_T_|R_E_C_N_O_|R_E_C_D_E_L_"
					aAdd(aDados, { Upper(names[i]), jsonObj[names[i]] })
					loop	
				endif
				aAdd(aDados, { Upper(names[i]), DecodeUtf8(PadR(jsonObj[names[i]], TamSX3(names[i])[01])) })
			else
				if ValType(item) == "A"
					//conout("Vetor[")
					for j := 1 to len(item)
						//conout("Indice " + cValtochar(j))
						u_PrintJson(item[j])
					next j
					//conout("]Vetor")
				endif
			endif
		next i

		//busca o primeiro indice conforme a tabela definida
		cInd := fGetIndice(cTabela, aDados)

		if Empty(cInd)
			return '{"status": "ERRO", "message":"Nao foi possivel montar a chave! ['+cTabela+']"}'
		EndIf

		DBSelectArea(cTabela)
		&(cTabela)->(DbSetOrder(01))
		if &(cTabela)->(DbSeek(cInd))
			lInc := .F.
		endif

		nPosDelete := aScan(aDados, {|x| Upper(AllTrim(x[1])) == "D_E_L_E_T_" })
		if nPosDelete > 0
			if !Empty(aDados[nPosDelete][2])
				lDeletado := .T.
				if lInc
					return '{"status": "OK", "message":"Registro descartado. Não existe na base e veio deletado! ['+cTabela+'] '+ cInd +'"}'
				endif
				RecLock(cTabela, .F.)
				&(cTabela)->(DbDelete())
				(cTabela)->(MsUnlock())
				return '{"status": "OK", "message":"Registro deletado com sucesso! ['+cTabela+'] '+ cInd +'"}'
			endif
		endif
		if RecLock(cTabela, lInc)
			for nX := 01 To Len(aDados)
				//Verifica se é o campo RECNO ou RECDEL e pula o loop.
				if(AllTrim(Upper(aDados[nX][01])) $ "R_E_C_N_O_|R_E_C_D_E_L_")
					loop
				endif
				/**
				Verifica se existe o R_E_C_D_E_L e grava o conteudo do R_E_C_N_O_ 
				caso esteja deletado.
				**/
				&(aDados[nX][01]) := fConvert(&(aDados[nX][01]), aDados[nX][02])
			next nX
			(cTabela)->(MsUnlock())
		endif

		cMessage := '{"status": "OK", "message":"Registro '+iif(lInc, 'incluido', 'alterado')+' com sucesso! ['+cTabela+'] '+ cInd +'"}'
		FreeObj(oJson)
	endif

	ErrorBlock(oError)
return cMessage
//-------------------------------------------------------------------
/*/{Protheus.doc} getTabela
description Retorna o nome da tabela conforme o campo informado.
@author  Ricardo Junior
@since  26/01/2021
@version 1.0
/*/
//-------------------------------------------------------------------
static function getTabela(aCampos)
	local nX := 00
	//Utiliza esse for para não pegar os campos RECNO, DELET e RECDEL para buscar a tabela do arquivo.
	for nX := 01 To Len(aCampos)
		if(Upper(aCampos[nX]) $ "R_E_C_N_O_|D_E_L_E_T_|R_E_C_D_E_L_")
			loop
		endif
		cCampo := aCampos[nX]
		exit
	next nX

	cTabela := SubStr(cCampo, 01, At("_", cCampo) -1)
	If Len(cTabela) == 2
		cTabela := "S"+cTabela
	EndIf
return UPPER(cTabela)
//-------------------------------------------------------------------
/*/{Protheus.doc} fGetIndice
description pega o indice das tabelas tratadas.
@author  Ricardo Junior
@since   26/01/2021
@version 1.0
/*/
//-------------------------------------------------------------------
static function fGetIndice(cTabela, aDados)
	Local cIndice 	:= ""
	Local nX		:= 0

	DbSelectArea(cTabela)
	&(cTabela)->(DbSetOrder(01))
	aCamposInd := StrTokArr( IndexKey(), "+" )

	for nX := 01 to Len(aCamposInd)
		if aScan(aDados, {|x| Upper(AllTrim(x[1])) == aCamposInd[nX] }) <= 0
			cIndice := ""
			exit
		endif
		cIndice += PadR(aDados[aScan(aDados, {|x| Upper(AllTrim(x[1])) == aCamposInd[nX] })][02], TamSx3(aCamposInd[nX])[01])
	next nX

Return cIndice
//-------------------------------------------------------------------
/*/{Protheus.doc} fConvert
description Converte o campo para o tipo do campo da base.
@author  Ricardo Junior
@since   26/01/2021
@version 1.0
/*/
//-------------------------------------------------------------------
static function fConvert(cCampo, cConteudo)
	Local xConteudo := Nil
	do case
		case Valtype(cCampo) == "D"
			xConteudo := SToD(cConteudo)
		Case ValType(cCampo) == "N"
			xConteudo := Val(cConteudo)
		Case ValType(cCampo) == "L"
			xConteudo := iIf(AllTrim(cCampo)=="F", .F., .T.)
		OtherWise
			xConteudo := cConteudo
	endcase
Return xConteudo
