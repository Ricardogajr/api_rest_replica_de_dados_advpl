# api_rest_replica_de_dados_advpl

Esta rotina foi desenvolvida pensando na utilização de replica entre bases do Protheus. 
É uma rotina bem simples, onde ela recebe dados de um arquivo JSON, numa API Rest e grava os dados na tabela do Protheus.
Como ele identifica a tabela? Simples, com as informações enviadas no JSON. Faço uma busca pegando algum campo e dele monto a tabela que vai ser importada.

A Rotina só possui o método POST. Ela foi desenvolvida desta forma, pois o sistema que iria fazer a extração dos dados e enviar, não saberia indentificar 
se é uma inclusão, alteração ou exclusão.
Pego o primeiro indice da tabela, e filtro os campos para ver se foram enviados no JSON. Com tudo ok, faço uma busca na base para verificar a existência.
Se existir, altera, senão inclui. Caso exista e o campo D_E_L_E_T_ venha preenchido, o sistema deleta.


Abaixo temos um exemplo de arquivo JSON. É Obrigatório que envie os campos existentes na base e os campos que fazem chave no indice da tabela.

{"bm_filial":"        ","bm_grupo":"0109","bm_desc":"DESPESAS C IMPOSTOS E CONTRIBUICOES","d_e_l_e_t_":" ","r_e_c_n_o_":"109","r_e_c_d_e_l_":"0","bm_xctcap":"            ","bm_xmiglt":"                            ","bm_tpsegp":" "}

Campos Recno e Recdel serão desconsiderados. Caso venha com o campo D_E_L_E_T_ preenchido ele dá um dbdelete() deletando o registro e preenchendo o campo D_E_L_E_T_ e o R_E_C_D_E_L caso exista.


Nesta versão, não contempla nenhuma questão de LOG.
