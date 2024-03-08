# OptimalTrading

Este módulo calcula a quantidade ótima a ser vendida para três tipos de clientes (large corps, big accounts e trading), considerando ceários de preço e geração.
Como input, são necessários:
  - Cenários de PLD, inseridos no arquivo data/pld_scenarios.csv
  - Cenários de geração, inseridos no arquivo data/generation_scenarios.csv
  - GF: Garantia física do portfólio existente
  - Qmax_large_corps: Percentual máximo da garantia física que pode ser alocada ao tipo de cliente large corps
  - Qmax_big_accounts: Percentual máximo da garantia física que pode ser alocada ao tipo de cliente big accounts
  - Qmax_trading: Percentual máximo da garantia física que pode ser alocada ao tipo de cliente de trading
  - P_large_corps: Preço do contrato a ser vendido ao tipo de cliente large corps
  - P_big_accounts: Preço do contrato a ser vendido ao tipo de cliente big accounts
  - P_trading: Preço do contrato a ser vendido ao tipo de cliente de trading
  - α: Nível de confiança para cálculo do VaR e CVaR
  - λ: Parâmetro de risco que pondera a combinação entre valor esperado e CVaR da receita (quanto maior o λ, mais o modelo levará em consideração o risco em relação ao valor esperado)
  - trading_year: Ano de contratação
  - seasonal_contract: Indica a possibilidade de contrato sazonal para um dos clientes. Se todos possuirem contratos flat, esse parâmetro deve ser "None". Caso contrário, deve ser indicado o tipo de cliente (large_corps, big_accounts ou trading)
  - change_pld: Indica aumento (> 1.0) ou redução (< 1.0) dos cenários de PLD.

Como saída, são exportados 3 arquivos CSVs:
  - optimal_Q.csv: Possui a quantidade contratada de cada tipo de cliente
  - revenue_scenarios.csv: Possui os cenários de receita resultantes
  - resume.csv: Apresenta a média, mediana, CVaR e VaR da receita, além do risco e o valor da função objetivo do problema.
