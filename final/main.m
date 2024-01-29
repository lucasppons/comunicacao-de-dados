clear;
close;

NUM_BITS = 10008;                                                        % n�mero de bits de dados a serem simulados
RAW_DATA = randi(2, 1, NUM_BITS)-1;

assert(mod(NUM_BITS, 4) == 0 && mod(NUM_BITS, 6) == 0, 'Para poder fazer puncturing, especifique uma quantidade de bits v�lida');

% https://sci-hub.se/10.1109/TCOM.1984.1096047
TWO_THIRDS_PUNCTURE = [1 0 1 1];
THREE_FOURTHS_PUNCTURE = [1 1 0 1 0 1];
TRELLIS = poly2trellis(7, [171 133]);
CONV_DATA_2_3 = convenc(RAW_DATA, TRELLIS, TWO_THIRDS_PUNCTURE);
CONV_DATA_3_4 = convenc(RAW_DATA, TRELLIS, THREE_FOURTHS_PUNCTURE);

QPSK_DATA = encode_qpsk(RAW_DATA); % bits aleat�rios modulados em QPSK (partes em 1 e -1)
QAM_DATA = encode_qam(RAW_DATA);

CONV_QPSK_DATA_2_3 = encode_qpsk(CONV_DATA_2_3);
CONV_QAM_DATA_2_3 = encode_qam(CONV_DATA_2_3);
CONV_QPSK_DATA_3_4 = encode_qpsk(CONV_DATA_3_4);
CONV_QAM_DATA_3_4 = encode_qam(CONV_DATA_3_4);

Eb_N0_dB = 0:1:9;                % faixa de Eb/N0
Eb_N0_lin = 10 .^ (Eb_N0_dB/10); % faixa de Eb/N0 linearizada

QPSK_BER = zeros(size(Eb_N0_lin));                                      % pr�-aloca��o do vetor de BER
QAM_BER = zeros(size(Eb_N0_lin));
CONV_2_3_QPSK_BER = zeros(size(Eb_N0_lin));
CONV_2_3_QAM_BER = zeros(size(Eb_N0_lin));
CONV_3_4_QPSK_BER = zeros(size(Eb_N0_lin));
CONV_3_4_QAM_BER = zeros(size(Eb_N0_lin));

ENERGY_PER_BIT_QPSK = 1;                                                % energia por bit para a modula��o QPSK utilizada
ENERGY_PER_BIT_QAM = mean((real(QAM_DATA).^2 + imag(QAM_DATA).^2)) / log2(64); % energia m�dia por bit do QAM (x^2 + y^2 = tamanho_do_vetor^2)

NP_QPSK = ENERGY_PER_BIT_QPSK ./ (Eb_N0_lin); % vetor de pot�ncias do ru�do
NA_QPSK = sqrt(NP_QPSK);                      % vetor de amplitudes do ru�do
NP_QAM = ENERGY_PER_BIT_QAM ./ (Eb_N0_lin);
NA_QAM = sqrt(NP_QAM);

for i = 1:length(Eb_N0_lin)
    % QPSK
    n = NA_QPSK(i)*complex(randn(1, length(QPSK_DATA)), randn(1, length(QPSK_DATA)))*sqrt(0.5); % vetor de ru�do complexo com desvio padr�o igual a uma posi��o do vetor NA
    r = QPSK_DATA + n;                                                        % vetor recebido
    QPSK_DEMOD = decode_qpsk(r);                       % QPSK: corrige a informa��o pra compensar pelo ruido (pode ser que corrija errado)
    QPSK_BER(i) = sum(RAW_DATA ~= QPSK_DEMOD(1:length(RAW_DATA))) / length(RAW_DATA);                    % contagem de erros e c�lculo do BER

    % 64-QAM
    n = NA_QAM(i)*complex(randn(1, length(QAM_DATA)), randn(1, length(QAM_DATA)))*sqrt(0.5);
    r = QAM_DATA + n;
    QAM_DEMOD = decode_qam(r);                                                % 64-QAM: corrige a informa��o pra compensar pelo ruido (pode ser que corrija errado)
    QAM_BER(i) = sum(RAW_DATA ~= QAM_DEMOD(1:length(RAW_DATA))) / length(RAW_DATA);                % contagem de erros e c�lculo do BER
    
    % QPSK + convolution coding 2/3
    n = NA_QPSK(i)*complex(randn(1, length(CONV_QPSK_DATA_2_3)), randn(1, length(CONV_QPSK_DATA_2_3)))*sqrt(0.5); % vetor de ru�do complexo com desvio padr�o igual a uma posi��o do vetor NA
    r = CONV_QPSK_DATA_2_3 + n;                                                        % vetor recebido
    QPSK_DEMOD = vitdec(decode_qpsk(r), TRELLIS, 32, 'trunc', 'hard', TWO_THIRDS_PUNCTURE);
    CONV_2_3_QPSK_BER(i) = sum(RAW_DATA ~= QPSK_DEMOD(1:length(RAW_DATA))) / length(RAW_DATA);                    % contagem de erros e c�lculo do BER

    % 64-QAM + convolution coding 2/3
    n = NA_QAM(i)*complex(randn(1, length(CONV_QAM_DATA_2_3)), randn(1, length(CONV_QAM_DATA_2_3)))*sqrt(0.5);
    r = CONV_QAM_DATA_2_3 + n;
    CONV_QAM_DEMOD = vitdec(decode_qam(r), TRELLIS, 32, 'trunc', 'hard', TWO_THIRDS_PUNCTURE);
    CONV_2_3_QAM_BER(i) = sum(CONV_QAM_DEMOD(1:length(RAW_DATA)) ~= RAW_DATA) / length(RAW_DATA);
    
    % QPSK + convolution coding 3/4
    n = NA_QPSK(i)*complex(randn(1, length(CONV_QPSK_DATA_3_4)), randn(1, length(CONV_QPSK_DATA_3_4)))*sqrt(0.5); % vetor de ru�do complexo com desvio padr�o igual a uma posi��o do vetor NA
    r = CONV_QPSK_DATA_3_4 + n;                                                        % vetor recebido
    QPSK_DEMOD = vitdec(decode_qpsk(r), TRELLIS, 32, 'trunc', 'hard', THREE_FOURTHS_PUNCTURE);
    CONV_3_4_QPSK_BER(i) = sum(RAW_DATA ~= QPSK_DEMOD(1:length(RAW_DATA))) / length(RAW_DATA);                    % contagem de erros e c�lculo do BER

    % 64-QAM + convolution coding 3/4
    n = NA_QAM(i)*complex(randn(1, length(CONV_QAM_DATA_3_4)), randn(1, length(CONV_QAM_DATA_3_4)))*sqrt(0.5);
    r = CONV_QAM_DATA_3_4 + n;
    CONV_QAM_DEMOD = vitdec(decode_qam(r), TRELLIS, 32, 'trunc', 'hard', THREE_FOURTHS_PUNCTURE);
    CONV_3_4_QAM_BER(i) = sum(CONV_QAM_DEMOD(1:length(RAW_DATA)) ~= RAW_DATA) / length(RAW_DATA);
end

QPSK_BER_THEORETICAL = erfc(sqrt(2*Eb_N0_lin)/sqrt(2)); % BER te�rico para compara��o
QAM_BER_THEORETICAL = 2/log2(64) * (1 - (1/sqrt(64))) * erfc(sqrt((3*log2(64)/(2*(64-1)))*Eb_N0_lin)); % BER te�rico para compara��o (https://www.etti.unibw.de/labalive/experiment/qam/)

semilogy(...
    Eb_N0_dB, CONV_2_3_QPSK_BER, 'b+', ...
    Eb_N0_dB, CONV_2_3_QAM_BER, 'r+', ...
    Eb_N0_dB, CONV_3_4_QPSK_BER, 'b*', ...
    Eb_N0_dB, CONV_3_4_QAM_BER, 'r*', ...
    Eb_N0_dB, QPSK_BER, 'bx', ...
    Eb_N0_dB, QAM_BER, 'rx', ...
    Eb_N0_dB, QAM_BER_THEORETICAL, 'r:', ...
    Eb_N0_dB, QPSK_BER_THEORETICAL, 'b:', ...
    'LineWidth', 2, 'MarkerSize', 10 ...
);

xlabel('Eb/N0 (dB)');
ylabel('BER');
legend(...
    'qpsk conv 2/3',...
    'qam conv 2/3',...
    'qpsk conv 3/4',...
    'qam conv 3/4',...
    'qpsk',...
    'qam',...
    'qam ter.',...
    'qpsk ter.'...
);