# api_rest_replica_de_dados_advpl

Esta rotina foi desenvolvida pensando na utilização de replica entre bases do Protheus. 
É uma rotina bem simples, onde ela recebe dados de um arquivo JSON, numa API Rest e grava os dados na tabela do Protheus.
Como ele identifica a tabela? Simples, com as informações enviadas no JSON. Faço uma busca pegando algum campo e dele monto a tabela que vai ser importada.

A Rotina só possui o método POST. Ela foi desenvolvida desta forma, pois o sistema que iria fazer a extração dos dados e enviar, não saberia indentificar 
se é uma inclusão, alteração ou exclusão.
Pego o primeiro indice da tabela, e filtro os campos para ver se foram enviados no JSON. Com tudo ok, faço uma busca na base para verificar a existência.
Se existir, altera, senão inclui. Caso exista e o campo D_E_L_E_T_ venha preenchido, o sistema deleta.

Nesta versão, não contempla nenhuma questão de LOG.
