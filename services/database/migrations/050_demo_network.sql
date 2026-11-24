-- The demo network (ir decision-demo-network): fourteen fictional people who
-- are already friends, members, scrappers and fans of one another, with
-- communities and forum threads to walk into, so a guest's first screen is a
-- network and not a blank. Every row is fiction; every id is a fixed uuid so
-- tests and fixtures can name one, the bulk rows numbered inside their
-- prefix. Applied once per fresh volume by initdb; ON CONFLICT DO NOTHING
-- makes a second application a no-op.

SET lock_timeout = '5s';
SET statement_timeout = '60s';

BEGIN;

INSERT INTO app_user (id, handle, display_name, photo_url, about, relationship, city, country, birthday, passions, music, movies, books, created_at) VALUES
  ('aa000000-0000-4000-8000-000000000001', 'mariana-costa', 'Mariana Costa', '/pictures/d8dab29a5736d5c2b0084d720d3db02c785560071609be501541922928fdf831.jpg', 'Designer de dia, DJ de sala de estar à noite. Coleciono cadernos que nunca termino.', 'rel_dating', 'São Paulo, SP', 'Brasil', '1986-03-14', 'café coado, bossa nova, papelaria', 'Tom Jobim, Los Hermanos, Marisa Monte', 'Central do Brasil, Amélie, Cidade de Deus', 'Clarice Lispector, Guimarães Rosa', now() - interval '400 days'),
  ('aa000000-0000-4000-8000-000000000002', 'rafael-lima', 'Rafael Lima', '/pictures/a634d4f02fe5b77804943c1d74b8d70e35ffe26454e0e9af9717432a2c72bfde.jpg', 'Mineiro, programador e torcedor sofrido. Se tem café, tem conversa.', 'rel_single', 'Belo Horizonte, MG', 'Brasil', '1984-07-02', 'Cruzeiro, pão de queijo, violão', 'Skank, Pato Fu, Clube da Esquina', 'Tropa de Elite, O Auto da Compadecida', 'Machado de Assis, Drummond', now() - interval '398 days'),
  ('aa000000-0000-4000-8000-000000000003', 'juliana-souza', 'Juliana Souza', '/pictures/ee794ad2b1016f820a8dffbfe5602d0ef612da197096715c1b200aac385c0017.jpg', 'Carioca da gema. Fotografo o Rio todo dia e ainda não me cansei.', 'rel_married', 'Rio de Janeiro, RJ', 'Brasil', '1985-11-23', 'praia às 7 da manhã, samba, fotografia', 'Cartola, Caetano Veloso, Legião Urbana', 'Tropa de Elite, Dona Flor e Seus Dois Maridos', 'Lygia Fagundes Telles, Rubem Fonseca', now() - interval '395 days'),
  ('aa000000-0000-4000-8000-000000000004', 'thiago-pereira', 'Thiago Pereira', '/pictures/21d6722e3baa38cb075afdc599a60c8861440a6dea431e7a8ff43f86d05190b9.jpg', 'Curitibano, portanto frio por fora. Pedalo mais do que falo.', 'rel_single', 'Curitiba, PR', 'Brasil', '1987-01-09', 'ciclismo, chuva, café especial', 'Pink Floyd, Radiohead, Relespública', 'Blade Runner, Matrix', 'Asimov, Tolkien', now() - interval '390 days'),
  ('aa000000-0000-4000-8000-000000000005', 'camila-rocha', 'Camila Rocha', '/pictures/11d956f8b1bf14c55157948c614aab760383cc7685163ed43e25609c7c050266.jpg', 'Atriz, professora de teatro e gaúcha de bairrismo moderado.', 'rel_complicated', 'Porto Alegre, RS', 'Brasil', '1983-09-30', 'chimarrão, teatro, Grêmio', 'Engenheiros do Hawaii, Nenhum de Nós, Cidadão Quem', 'O Homem que Copiava, Antes do Amanhecer', 'Erico Verissimo, Mario Quintana', now() - interval '380 days'),
  ('aa000000-0000-4000-8000-000000000006', 'bruno-almeida', 'Bruno Almeida', '/pictures/60c2053e9aa4900708d262ddb15313d1f5b9e5daad2c0f6ace8c41f4fd78a015.jpg', 'Pernambucano. Carnaval é religião e o resto do ano é ensaio.', 'rel_dating', 'Recife, PE', 'Brasil', '1986-05-17', 'frevo, carnaval de Olinda, bolo de rolo', 'Chico Science, Alceu Valença, Mundo Livre S/A', 'Baile Perfumado, Amarelo Manga', 'Ariano Suassuna, João Cabral de Melo Neto', now() - interval '370 days'),
  ('aa000000-0000-4000-8000-000000000007', 'fernanda-dias', 'Fernanda Dias', '/pictures/f22764f3355bb916a04e578d85b3078c4efcd804fe83018ec6ac97ab56e82b5f.jpg', 'Baiana, estudante de medicina, sorrindo mesmo quando tá difícil.', 'rel_single', 'Salvador, BA', 'Brasil', '1988-02-05', 'acarajé, axé, pôr do sol no Porto da Barra', 'Ivete Sangalo, Gilberto Gil, Olodum', 'Ó Paí, Ó; Cidade Baixa', 'Jorge Amado', now() - interval '360 days'),
  ('aa000000-0000-4000-8000-000000000008', 'lucas-martins', 'Lucas Martins', '/pictures/8c7df7267d485c5d3e33644f059c1a25940056d6c4eef9e89d7091eaf250fa2e.jpg', 'Brasiliense, concurseiro em pausa e gamer sem pausa.', 'rel_single', 'Brasília, DF', 'Brasil', '1985-12-12', 'videogame, Legião Urbana, churrasco no Lago', 'Legião Urbana, Capital Inicial, Plebe Rude', 'O Senhor dos Anéis, Star Wars', 'Neil Gaiman, Douglas Adams', now() - interval '350 days'),
  ('aa000000-0000-4000-8000-000000000009', 'patricia-nunes', 'Patrícia Nunes', '/pictures/9f797e4acee1a4de4f9b4c3aa1cc4e89d7c9efd5dbff1c463d88374ed601d719.jpg', 'Cearense, mãe da Lia, viciada em forró pé de serra.', 'rel_married', 'Fortaleza, CE', 'Brasil', '1982-08-21', 'forró, Canoa Quebrada, tapioca', 'Fagner, Belchior, Mastruz com Leite', 'Cine Holliúdy, Lisbela e o Prisioneiro', 'Rachel de Queiroz', now() - interval '340 days'),
  ('aa000000-0000-4000-8000-000000000010', 'diego-ferreira', 'Diego Ferreira', '/pictures/57c0787e260e4785a6d858d26ff60a82fd5ae48cbae32fe6e866cb3daf7fe1a4.jpg', 'Manezinho de adoção. Se o mar tá bom, eu não tô.', 'rel_dating', 'Florianópolis, SC', 'Brasil', '1987-06-28', 'surf, mate gelado, ponte Hercílio Luz', 'Dazaranha, Jack Johnson, Natiruts', 'Ponto de Mutação, Wall-E', 'Paulo Leminski', now() - interval '330 days'),
  ('aa000000-0000-4000-8000-000000000011', 'aline-barros', 'Aline Barros', '/pictures/1468690451b81be74fdf90ee11d190bb1d226560f532cf4a883b50fc5dfaebcc.jpg', 'Amazonense, bióloga de formação e sapateira de coração.', 'rel_single', 'Manaus, AM', 'Brasil', '1989-04-03', 'tacacá, Teatro Amazonas, boi-bumbá', 'Carrapicho, Ednaldo Pereira, Gaby Amarantos', 'Tainá, Serras da Desordem', 'Milton Hatoum', now() - interval '320 days'),
  ('aa000000-0000-4000-8000-000000000012', 'gustavo-ramos', 'Gustavo Ramos', '/pictures/2f61d9e108f2a1074fb07703cadf176da43f5efb8782537cf07048680fc74e44.jpg', 'Goiano, engenheiro agrônomo e dono do melhor arroz com pequi da região.', 'rel_open', 'Goiânia, GO', 'Brasil', '1984-10-15', 'sertanejo raiz, pequi, pamonha', 'Boca do Forno, Chitãozinho & Xororó, Marília Mendonça', '2 Filhos de Francisco', 'Bernardo Élis, Cora Coralina', now() - interval '310 days'),
  ('aa000000-0000-4000-8000-000000000013', 'beatriz-moreira', 'Beatriz Moreira', '/pictures/f07b84f12ef125cbb837a7bd64da401992f5f62bd55fee10d01cd3dcc8abae80.jpg', 'Estudante de letras, cicloativista. Chove e eu saio de bike mesmo assim.', 'rel_single', 'Campinas, SP', 'Brasil', '1990-07-19', 'bicicleta, Unicamp, jazz', 'Elis Regina, Céu, Tulipa Ruiz', 'O Ano em que Meus Pais Saíram de Férias', 'Hilda Hilst, Ana Cristina Cesar', now() - interval '300 days'),
  ('aa000000-0000-4000-8000-000000000014', 'andre-carvalho', 'André Carvalho', '/pictures/f2f9f7b26611e3cd3a9bc8c909a8fb8dd74494334d847e013fcbf2dc737a0b81.jpg', 'Paraense, chef de cozinha e defensor do açaí sem granola.', 'rel_married', 'Belém, PA', 'Brasil', '1983-03-27', 'Círio de Nazaré, tacacá, Ver-o-Peso', 'Dona Onete, Pinduca, Felipe Cordeiro', 'Para Todas as Idades', 'Dalcídio Jurandir', now() - interval '290 days')
ON CONFLICT DO NOTHING;

-- Friendships, stated once per pair and mirrored here by hand: the 015
-- trigger mints edges from an accepted request, and these were never asked.
WITH pairs (a, b, age) AS (VALUES
  (1, 2, 280), (1, 3, 270), (1, 4, 260), (1, 13, 120), (1, 7, 200),
  (2, 4, 250), (2, 8, 240), (2, 12, 150), (2, 5, 90),
  (3, 6, 230), (3, 7, 220), (3, 9, 210), (3, 5, 80),
  (4, 10, 200), (4, 13, 110), (4, 12, 60),
  (5, 10, 190), (5, 13, 100),
  (6, 7, 180), (6, 14, 170), (6, 9, 70),
  (7, 11, 160),
  (8, 10, 150), (8, 12, 140), (8, 13, 50),
  (9, 11, 130), (9, 14, 120),
  (10, 13, 40),
  (11, 14, 30),
  (12, 14, 20)
), ids AS (
  SELECT ('aa000000-0000-4000-8000-0000000000' || lpad(a::text, 2, '0'))::uuid AS ua,
         ('aa000000-0000-4000-8000-0000000000' || lpad(b::text, 2, '0'))::uuid AS ub,
         now() - make_interval(days => age) AS at
  FROM pairs
)
INSERT INTO friendship (user_id, friend_id, created_at)
SELECT ua, ub, at FROM ids UNION ALL SELECT ub, ua, at FROM ids
ON CONFLICT DO NOTHING;

INSERT INTO community (id, name, description, category, owner_id, photo_url, created_at) VALUES
  ('cc000000-0000-4000-8000-000000000001', 'Eu odeio acordar cedo', 'Se fosse pra gente acordar cedo, o sol nasceria às dez.', 'cat_humor', 'aa000000-0000-4000-8000-000000000001', '/pictures/85c0634f129c09dceba569f5dfeaf1fff72dbbfda9a84f71a9c5508fa7a80c32.jpg', now() - interval '285 days'),
  ('cc000000-0000-4000-8000-000000000002', 'Eu amo pizza', 'Para quem sabe que pizza é refeição completa. Abacaxi na pizza: o debate está no fórum.', 'cat_food', 'aa000000-0000-4000-8000-000000000002', '/pictures/dda0627d2a2b977c2e4464f37dc20c849cfb80423b784ef1742702660db28bad.jpg', now() - interval '280 days'),
  ('cc000000-0000-4000-8000-000000000003', 'Legião Urbana', 'Que país é este? Fãs do Renato, do Dado e do Bonfá.', 'cat_music', 'aa000000-0000-4000-8000-000000000008', '/pictures/9dcd273fa3924bacb8617eee8da663c3233497ff0eeb2aa255c559a5e1f4b638.jpg', now() - interval '275 days'),
  ('cc000000-0000-4000-8000-000000000004', 'Programadores Brasil', 'Java, PHP, Delphi e flame wars respeitosas.', 'cat_tech', 'aa000000-0000-4000-8000-000000000002', '/pictures/01fcc3fe43877ad3ad8cfc5e49b405bcb4069d29562718f29afc9d71b455a7f9.jpg', now() - interval '270 days'),
  ('cc000000-0000-4000-8000-000000000005', 'Eu não vivo sem café', 'Coado, expresso, de garrafa térmica. Tanto faz. Só não tira.', 'cat_food', 'aa000000-0000-4000-8000-000000000001', '/pictures/588be611b9e1998a9b4cda198cfcf4d4671e631d23e1fba0f4b8699743e2deb5.jpg', now() - interval '260 days'),
  ('cc000000-0000-4000-8000-000000000006', 'Cinema Nacional', 'Do Cinema Novo ao Tropa de Elite: aqui a gente discute filme brasileiro.', 'cat_movies', 'aa000000-0000-4000-8000-000000000003', '/pictures/3e0d9beae45ae3d7eb0f4216f5df25251b876e7d72795ca43b88b5b7b49863a6.jpg', now() - interval '250 days'),
  ('cc000000-0000-4000-8000-000000000007', 'Churrasco de domingo', 'Carne, carvão e a maionese da tia.', 'cat_food', 'aa000000-0000-4000-8000-000000000005', '/pictures/e42ff3507a1e26787e4c6d7af27a2e761ae1d26fb565c1a83f0fb812b1674c0d.jpg', now() - interval '240 days'),
  ('cc000000-0000-4000-8000-000000000008', 'Yogurt 2004 — eu estava lá', 'Convite por e-mail, depoimento com glitter, perfil cem por cento sincero.', 'cat_humor', 'aa000000-0000-4000-8000-000000000004', NULL, now() - interval '230 days'),
  ('cc000000-0000-4000-8000-000000000009', 'Eu falo sozinho', 'E respondo. E discordo.', 'cat_humor', 'aa000000-0000-4000-8000-000000000013', NULL, now() - interval '200 days'),
  ('cc000000-0000-4000-8000-000000000010', 'Mochileiros da América do Sul', 'Dicas, roteiros e o ônibus mais barato pra Bolívia.', 'cat_travel', 'aa000000-0000-4000-8000-000000000010', '/pictures/0879d4e6629deb95029428cc6487991df2adef83fb7554b5a09f85c77ac7c912.jpg', now() - interval '180 days'),
  ('cc000000-0000-4000-8000-000000000011', 'Carnaval de Olinda', 'Ladeiras, frevo e o Homem da Meia-Noite.', 'cat_cities', 'aa000000-0000-4000-8000-000000000006', '/pictures/13fcc0b5cb986624e1353497f409f919dc1af235814f28ad14f949949148a7d2.jpg', now() - interval '160 days'),
  ('cc000000-0000-4000-8000-000000000012', 'Flamengo', 'Uma vez Flamengo, sempre Flamengo.', 'cat_sports', 'aa000000-0000-4000-8000-000000000003', '/pictures/14b54abf1d09a7514caa94712cacf00f7da9dac3d488eef547df429c01226587.jpg', now() - interval '140 days')
ON CONFLICT DO NOTHING;

WITH m (c, u) AS (VALUES
  (1, 1), (1, 2), (1, 4), (1, 8), (1, 13), (1, 7), (1, 10), (1, 5),
  (2, 2), (2, 1), (2, 3), (2, 8), (2, 12), (2, 14), (2, 13),
  (3, 8), (3, 3), (3, 2), (3, 13), (3, 5), (3, 12),
  (4, 2), (4, 4), (4, 8), (4, 10), (4, 13),
  (5, 1), (5, 2), (5, 4), (5, 9), (5, 12), (5, 14), (5, 3),
  (6, 3), (6, 1), (6, 5), (6, 6), (6, 13), (6, 11),
  (7, 5), (7, 2), (7, 10), (7, 12), (7, 8),
  (8, 4), (8, 1), (8, 2), (8, 3), (8, 5), (8, 6), (8, 7), (8, 8), (8, 9), (8, 10), (8, 11), (8, 12), (8, 13), (8, 14),
  (9, 13), (9, 1), (9, 4), (9, 5), (9, 9),
  (10, 10), (10, 4), (10, 13), (10, 6), (10, 11),
  (11, 6), (11, 7), (11, 3), (11, 14), (11, 9),
  (12, 3), (12, 7), (12, 9), (12, 14), (12, 11)
)
INSERT INTO membership (community_id, user_id, created_at)
SELECT ('cc000000-0000-4000-8000-0000000000' || lpad(c::text, 2, '0'))::uuid,
       ('aa000000-0000-4000-8000-0000000000' || lpad(u::text, 2, '0'))::uuid,
       now() - make_interval(days => 100 + c * 3 + u)
FROM m
ON CONFLICT DO NOTHING;

WITH s (owner, author, body, hours) AS (VALUES
  (1, 2, 'Oi Mari! Passando pra deixar um recado e dizer que a playlist de sexta tava ótima. Bjs', 5),
  (1, 3, 'Mariiii, me manda a foto do caderno novo? Quero copiar a ideia descaradamente.', 20),
  (1, 13, 'Chegou o livro da Hilda que você indicou. Primeiro poema e eu já desisti de ser normal.', 44),
  (1, 7, 'Quando você vem pra Salvador? O acarajé da Dinha não espera.', 70),
  (1, 4, 'Vi que você entrou na comunidade do café. Curitiba te espera com 12 graus e um coado.', 120),
  (2, 1, 'Rafa, o bug era vírgula. Sempre é vírgula. Me paga um pão de queijo.', 3),
  (2, 4, 'Cruzeiro ou Atlético hoje? Pergunto só pra te ver nervoso.', 30),
  (2, 8, 'Terminei o Baldur''s Gate. Agora sim podemos conversar sobre a vida.', 52),
  (2, 12, 'Gustavo, aquela pamonha chegou quente em BH? Milagre dos Correios.', 96),
  (2, 5, 'Camila, bem-vinda à comunidade do churrasco. A regra é: quem chega, assa.', 140),
  (3, 1, 'Ju, suas fotos do Arpoador deviam estar num livro. Sério.', 8),
  (3, 6, 'Carnaval em Olinda, fechou? Já comprei a passagem e o protetor solar.', 36),
  (3, 7, 'Juliana, você viu o pôr do sol de ontem? Salvador ganhou do Rio, desculpa.', 60),
  (3, 9, 'Sobrinha mandou um beijo pra tia Ju. E eu mando outro.', 110),
  (3, 5, 'Vamos ver a peça da Camila em agosto? Ela jura que não é longa.', 170),
  (4, 1, 'Thiago, chove em Curitiba hoje? (pergunta retórica)', 12),
  (4, 10, 'Pedalei 40km hoje pensando no mate gelado que você falou. Veneno.', 48),
  (4, 13, 'Bia, Campinas até Curitiba de bike: loucura ou projeto de férias?', 90),
  (4, 2, 'Rafa, troquei o café por chá uma semana. Não recomendo.', 150),
  (5, 10, 'Camila, a peça foi incrível! Chorei no final e não era de rir.', 15),
  (5, 13, 'Me ensina a fazer chimarrão direito? Fiz e virou sopa de erva.', 66),
  (5, 3, 'Gaúcha, o Grêmio ganhou e eu lembrei de você. Abraço do Rio!', 130),
  (6, 7, 'Bruno, o frevo que você mandou tá tocando aqui em Salvador desde ontem.', 9),
  (6, 14, 'Chef, bolo de rolo contra açaí: quem ganha? Fórum da comida te espera.', 40),
  (6, 3, 'Já te disse que você vai amar o Homem da Meia-Noite? Pois é.', 75),
  (7, 1, 'Fê, passei na prova! Sorriso liberado por decreto.', 6),
  (7, 11, 'Aline, as fotos do Teatro Amazonas me convenceram. Férias em Manaus.', 33),
  (7, 6, 'Fernanda, guarda um acarajé pra mim que eu chego sexta.', 100),
  (8, 2, 'Lucas, a comunidade da Legião passou de 100 membros! Que país é este.', 18),
  (8, 10, 'Churrasco no Lago sábado. Leva a prancha, vai que.', 55),
  (8, 12, 'Gustavo, o concurso foi adiado de novo. Pamonha de consolo?', 125),
  (9, 3, 'Patrícia, a Lia tá enorme! Manda mais fotos.', 24),
  (9, 11, 'Forró em Canoa Quebrada em julho. Confirma logo!', 80),
  (9, 14, 'André, sua receita de tapioca com carne de sol salvou meu domingo.', 160),
  (10, 4, 'Diego, o mar tava bom hoje? Então você não tava.', 11),
  (10, 5, 'Mochileiros, roteiro Bolívia fechado. 14 horas de ônibus de alegria.', 58),
  (10, 8, 'Trouxe a prancha pro Lago. Não deu certo. Mas deu risada.', 135),
  (11, 7, 'Aline, chegou o tacacá? Perguntando pelo meu estômago.', 27),
  (11, 9, 'Boi-bumbá esse ano vai ser em Parintins ou aqui mesmo?', 88),
  (12, 2, 'Gustavo, arroz com pequi na próxima visita. Não é pedido, é intimação.', 14),
  (12, 14, 'Chef paraense, aceita um desafio goiano? Pequi vs. jambu.', 95),
  (13, 1, 'Bia, obrigada pelo poema. Colei no caderno que eu nunca termino.', 2),
  (13, 4, 'Thiago, choveu em Campinas e eu saí de bike mesmo assim. Em sua honra.', 41),
  (13, 8, 'Lucas, Neil Gaiman chegou. Dormir é pra os fracos.', 105),
  (14, 6, 'André, o Círio foi lindo esse ano. Saudade do Ver-o-Peso.', 19),
  (14, 11, 'Chef, açaí sem granola é a causa mais justa desse site.', 62),
  (14, 12, 'Jambu ganhou. Aceito o segundo round em Goiânia.', 150)
)
INSERT INTO scrap (id, owner_id, author_id, body, created_at)
SELECT ('5c000000-0000-4000-8000-' || lpad((row_number() over ())::text, 12, '0'))::uuid,
       ('aa000000-0000-4000-8000-0000000000' || lpad(owner::text, 2, '0'))::uuid,
       ('aa000000-0000-4000-8000-0000000000' || lpad(author::text, 2, '0'))::uuid,
       body, now() - make_interval(hours => hours)
FROM s
ON CONFLICT DO NOTHING;

WITH t (subject, author, body, approved, days) AS (VALUES
  (1, 2, 'A Mari é a pessoa que te manda uma playlist no meio da tarde e acerta exatamente o que você precisava ouvir. Designer de talento, amiga de verdade, e a melhor DJ de sala de estar de São Paulo.', true, 200),
  (1, 3, 'Conheci a Mariana numa fila de show e saímos de lá amigas. Ela tem um olhar para as coisas pequenas que eu nunca vi em ninguém.', true, 150),
  (2, 1, 'O Rafa resolve qualquer bug e qualquer briga de bar com a mesma calma. Mineiro de verdade: fala pouco, faz muito, e o café é sempre dele.', true, 190),
  (2, 4, 'Programador honesto e cruzeirense sofredor. Duas qualidades raras. Recomendo para projetos e para finais de campeonato.', true, 100),
  (3, 1, 'A Ju fotografa o Rio como quem fotografa a família. Carioca de coração aberto, sempre com uma praia pra sugerir.', true, 180),
  (3, 6, 'Juliana foi a primeira a aceitar meu convite pro Carnaval de Olinda sem perguntar o preço. Isso diz tudo.', true, 60),
  (4, 1, 'O Thiago parece frio, mas é só o clima. Pedala, pensa e aparece com a resposta certa dois dias depois.', true, 170),
  (5, 3, 'A Camila em cena é outra pessoa; fora dela é a melhor conselheira que conheço. Gaúcha de bairrismo moderado, como ela mesma diz.', true, 50),
  (6, 7, 'Bruno é o carnaval em pessoa. Alegria contagiante e um coração do tamanho de Olinda.', true, 140),
  (7, 3, 'A Fê sorri até em plantão de 24 horas. Vai ser a melhor médica da Bahia, aposto meu acarajé.', true, 130),
  (8, 2, 'Lucas conhece todas as letras da Legião e todos os finais do Baldur''s Gate. Amigo leal, inimigo mortal no videogame.', true, 120),
  (9, 11, 'A Patrícia é mãe, forrozeira e a pessoa mais organizada que já viajou comigo. Canoa Quebrada nunca mais foi a mesma.', true, 70),
  (10, 4, 'Diego surfa de manhã e trabalha de tarde, nessa ordem, sempre. Se o mar tá bom, ele não tá — e tudo bem.', true, 90),
  (11, 14, 'Aline conhece cada rua de Manaus e cada bicho da floresta pelo nome. Bióloga e sapateira: eu também não entendi, mas funciona.', true, 20),
  (12, 2, 'O Gustavo é o único que faz pamonha chegar quente pelos Correios. Engenheiro agrônomo e mágico.', true, 80),
  (13, 1, 'A Bia lê Hilda Hilst debaixo de chuva, de bicicleta. Estudante de letras com alma de poeta e pernas de ciclista.', true, 40),
  (14, 6, 'O André cozinha como quem conta história. Chef paraense e defensor de causas justas, como o açaí sem granola.', true, 30),
  (1, 13, 'Mariana, você me ensinou a ouvir Elis Regina de novo. Obrigada por ser a amiga que indica livro e cobra a leitura.', false, 1),
  (2, 12, 'Rafa, o melhor dev que já me ajudou a plantar soja com planilha. Sério.', false, 2)
), rows AS (
  SELECT ('de000000-0000-4000-8000-' || lpad((row_number() over ())::text, 12, '0'))::uuid AS id,
         ('aa000000-0000-4000-8000-0000000000' || lpad(subject::text, 2, '0'))::uuid AS subject_id,
         ('aa000000-0000-4000-8000-0000000000' || lpad(author::text, 2, '0'))::uuid AS author_id,
         body, approved, now() - make_interval(days => days) AS created_at
  FROM t
), published AS (
  INSERT INTO testimonial (id, subject_id, author_id, body, created_at)
  SELECT id, subject_id, author_id, body, created_at FROM rows WHERE approved
  ON CONFLICT DO NOTHING
)
-- The two still waiting: the writer's half alone; the mirror writes the
-- subject's, and refuses a second copy.
INSERT INTO testimonial_draft (id, subject_id, author_id, body, created_at)
SELECT id, subject_id, author_id, body, created_at FROM rows WHERE NOT approved
ON CONFLICT DO NOTHING;

WITH f (fan, idol) AS (VALUES
  (2, 1), (3, 1), (4, 1), (13, 1), (7, 1), (12, 1),
  (1, 2), (4, 2), (8, 2), (5, 2),
  (1, 3), (6, 3), (7, 3), (9, 3), (5, 3),
  (1, 4), (10, 4), (13, 4),
  (10, 5), (3, 5), (13, 5),
  (7, 6), (14, 6), (3, 6),
  (1, 7), (3, 7), (6, 7), (11, 7),
  (2, 8), (10, 8),
  (11, 9), (3, 9),
  (4, 10), (8, 10),
  (14, 11), (7, 11),
  (2, 12), (8, 12),
  (1, 13), (4, 13), (5, 13), (8, 13),
  (6, 14), (12, 14)
)
INSERT INTO fan (fan_id, idol_id, created_at)
SELECT ('aa000000-0000-4000-8000-0000000000' || lpad(fan::text, 2, '0'))::uuid,
       ('aa000000-0000-4000-8000-0000000000' || lpad(idol::text, 2, '0'))::uuid,
       now() - make_interval(days => 10 + fan + idol)
FROM f
ON CONFLICT DO NOTHING;

WITH k (rater, rated, trust, cool, sexy) AS (VALUES
  (2, 1, 3, 3, 2), (3, 1, 3, 3, 3), (4, 1, 3, 2, 2), (13, 1, 3, 3, 3),
  (1, 2, 3, 2, 2), (4, 2, 3, 3, 1), (8, 2, 2, 3, 2),
  (1, 3, 3, 3, 3), (6, 3, 3, 3, 2), (7, 3, 3, 2, 3),
  (1, 4, 3, 2, 2), (10, 4, 2, 3, 2),
  (3, 5, 3, 3, 3), (10, 5, 2, 3, 2),
  (7, 6, 3, 3, 3), (14, 6, 3, 2, 2),
  (1, 7, 3, 3, 3), (3, 7, 3, 3, 3), (6, 7, 2, 3, 3),
  (2, 8, 3, 2, 1), (10, 8, 2, 3, 2),
  (3, 9, 3, 3, 2), (11, 9, 3, 2, 2),
  (4, 10, 2, 3, 3), (8, 10, 2, 3, 2),
  (7, 11, 3, 3, 2), (14, 11, 3, 2, 2),
  (2, 12, 3, 2, 2), (8, 12, 2, 2, 2),
  (1, 13, 3, 3, 3), (4, 13, 3, 3, 2),
  (6, 14, 3, 3, 2), (12, 14, 2, 3, 2)
)
INSERT INTO karma (rater_id, rated_id, trust, cool, sexy, created_at)
SELECT ('aa000000-0000-4000-8000-0000000000' || lpad(rater::text, 2, '0'))::uuid,
       ('aa000000-0000-4000-8000-0000000000' || lpad(rated::text, 2, '0'))::uuid,
       trust, cool, sexy, now() - make_interval(days => 5 + rater + rated)
FROM k
ON CONFLICT DO NOTHING;

INSERT INTO topic (id, community_id, author_id, title, body, created_at) VALUES
  ('dd000000-0000-4000-8000-000000000001', 'cc000000-0000-4000-8000-000000000001', 'aa000000-0000-4000-8000-000000000001', 'Qual é a sua hora limite pra acordar?', 'Pra mim é 9h30. Antes disso o corpo funciona mas a alma fica na cama. E vocês?', now() - interval '40 days'),
  ('dd000000-0000-4000-8000-000000000002', 'cc000000-0000-4000-8000-000000000001', 'aa000000-0000-4000-8000-000000000008', 'Despertador: celular ou aquele de dar corda?', 'O de corda não tem botão de soneca, o que é uma violência. Mas funciona.', now() - interval '12 days'),
  ('dd000000-0000-4000-8000-000000000003', 'cc000000-0000-4000-8000-000000000002', 'aa000000-0000-4000-8000-000000000002', 'Abacaxi na pizza: a verdade', 'Abro o tópico já sabendo que vou perder amigos. Abacaxi na pizza é bom. Pronto, falei.', now() - interval '35 days'),
  ('dd000000-0000-4000-8000-000000000004', 'cc000000-0000-4000-8000-000000000002', 'aa000000-0000-4000-8000-000000000014', 'Melhor pizzaria de cada cidade', 'Chef aqui. Quero montar um mapa. Comecem pela sua cidade e justifiquem.', now() - interval '9 days'),
  ('dd000000-0000-4000-8000-000000000005', 'cc000000-0000-4000-8000-000000000003', 'aa000000-0000-4000-8000-000000000008', 'Qual letra da Legião define a sua vida?', 'A minha é Tempo Perdido, e não aceito julgamento.', now() - interval '30 days'),
  ('dd000000-0000-4000-8000-000000000006', 'cc000000-0000-4000-8000-000000000003', 'aa000000-0000-4000-8000-000000000003', 'Show de Brasília 88: quem estava lá?', 'Minha tia jura que estava. Alguém mais tem tia que estava?', now() - interval '6 days'),
  ('dd000000-0000-4000-8000-000000000007', 'cc000000-0000-4000-8000-000000000004', 'aa000000-0000-4000-8000-000000000002', 'Java ou PHP para começar?', 'Um amigo quer aprender a programar e me perguntou. Respondi Python e ele ficou confuso. Ajudem.', now() - interval '28 days'),
  ('dd000000-0000-4000-8000-000000000008', 'cc000000-0000-4000-8000-000000000004', 'aa000000-0000-4000-8000-000000000004', 'Teclado mecânico vale o preço?', 'Comprei um e minha vizinha quer se mudar. Vale ou não vale?', now() - interval '4 days'),
  ('dd000000-0000-4000-8000-000000000009', 'cc000000-0000-4000-8000-000000000005', 'aa000000-0000-4000-8000-000000000001', 'Coado ou expresso?', 'Coado no filtro de pano, em casa, às 7h. Me convençam do contrário.', now() - interval '25 days'),
  ('dd000000-0000-4000-8000-000000000010', 'cc000000-0000-4000-8000-000000000006', 'aa000000-0000-4000-8000-000000000003', 'Central do Brasil ou Cidade de Deus?', 'Os dois são obras-primas, mas um deles te faz chorar na rodoviária. Escolham.', now() - interval '22 days'),
  ('dd000000-0000-4000-8000-000000000011', 'cc000000-0000-4000-8000-000000000007', 'aa000000-0000-4000-8000-000000000005', 'Ponto da carne: regras da casa', 'Mal passada é o único ponto. Bem passada é churrasco de castigo. Discutam.', now() - interval '18 days'),
  ('dd000000-0000-4000-8000-000000000012', 'cc000000-0000-4000-8000-000000000008', 'aa000000-0000-4000-8000-000000000004', 'Seu primeiro depoimento com glitter', 'O meu dizia "amigo pra toda hora" em rosa piscando. Confessem os seus.', now() - interval '15 days'),
  ('dd000000-0000-4000-8000-000000000013', 'cc000000-0000-4000-8000-000000000010', 'aa000000-0000-4000-8000-000000000010', 'Roteiro de 15 dias: Bolívia e Peru', 'Saindo de Floripa. Ônibus até Corumbá, trem até Santa Cruz, e depois a gente vê.', now() - interval '11 days'),
  ('dd000000-0000-4000-8000-000000000014', 'cc000000-0000-4000-8000-000000000011', 'aa000000-0000-4000-8000-000000000006', 'Onde ficar em Olinda no Carnaval', 'Quem tem casa de amigo tem tudo. Quem não tem, me chama que eu arrumo um colchão.', now() - interval '8 days'),
  ('dd000000-0000-4000-8000-000000000015', 'cc000000-0000-4000-8000-000000000012', 'aa000000-0000-4000-8000-000000000003', 'Maior ídolo da história?', 'Zico. Tópico encerrado. Mas podem comentar.', now() - interval '3 days')
ON CONFLICT DO NOTHING;

WITH p (topic, author, body, hours) AS (VALUES
  (1, 8, '9h30 é otimismo. Meu limite é meio-dia e mesmo assim de mau humor.', 950),
  (1, 4, 'Acordo às 6 pra pedalar e não entendo essa comunidade. Entrei pra estudar vocês.', 940),
  (1, 13, 'Thiago, você é o espião que a gente merece. Meu limite é 10h.', 930),
  (1, 7, 'Plantão de 24h me deixou sem opinião sobre horário. Qualquer hora é cedo.', 900),
  (2, 1, 'Celular, mas com 7 alarmes. Nenhum funciona.', 280),
  (2, 10, 'Meu despertador é o sol na janela. Floripa não tem cortina, só tem desculpa.', 260),
  (3, 1, 'Rafa, eu te amo, mas não.', 830),
  (3, 14, 'Como chef, declaro: abacaxi na pizza é legítimo se a massa for boa. Ponto.', 820),
  (3, 8, 'Chef falou, tá falado. Mas eu continuo pedindo de calabresa.', 810),
  (3, 13, 'Nunca pensei que uma comunidade de pizza ia me emocionar. Abacaxi sim.', 800),
  (4, 2, 'BH: qualquer uma que aceite pão de queijo como entrada.', 210),
  (4, 3, 'Rio: a do Baixo Gávea que todo mundo conhece e ninguém sabe o nome.', 200),
  (4, 12, 'Goiânia: a da esquina da minha rua, porque é da minha tia.', 190),
  (5, 2, 'Pais e Filhos. Toda vez, sem exceção, choro no segundo verso.', 700),
  (5, 13, 'Faroeste Caboclo, porque minha vida também não cabe em três minutos.', 690),
  (5, 5, 'Índios. Quando eu era criança achava que era sobre índios.', 680),
  (5, 12, 'Eduardo e Mônica, porque minha namorada é a Mônica e eu nem gosto de Bandeira.', 670),
  (6, 8, 'Minha tia também estava. Acho que o show tinha 400 mil tias.', 140),
  (6, 2, 'Tia é a unidade de medida oficial de shows dos anos 80.', 130),
  (7, 4, 'Python, e seu amigo tem razão de ficar confuso. Depois ele agradece.', 660),
  (7, 8, 'Java. Sofra cedo, sofra de uma vez.', 650),
  (7, 10, 'JavaScript. Ele vai usar de qualquer jeito, melhor saber logo.', 640),
  (7, 13, 'Letras aqui. Vocês sabem que isso tudo soa como poesia concreta, né?', 630),
  (8, 2, 'Vale. Minha vizinha também se mudou. Coincidência.', 90),
  (8, 10, 'Comprei o silencioso. Ninguém acreditou que era mecânico. Vitória?', 80),
  (9, 2, 'Expresso, porque sou mineiro e tenho pressa só pra café.', 590),
  (9, 4, 'Coado, filtro de papel, água a 92 graus. Sim, eu meço.', 580),
  (9, 14, 'Café de garrafa térmica na cozinha do restaurante, às 5h. Não é escolha, é sobrevivência.', 570),
  (9, 9, 'Café com tapioca. Ninguém perguntou mas eu respondi.', 560),
  (10, 1, 'Central do Brasil. Fernanda Montenegro na rodoviária é um país inteiro.', 520),
  (10, 5, 'Cidade de Deus, porque eu dou aula de teatro e ainda estudo aquela montagem de elenco.', 510),
  (10, 6, 'Vou de Baile Perfumado só pra estragar a enquete.', 500),
  (11, 2, 'Ao ponto pra mal. Bem passada é pra quem não confia no churrasqueiro.', 430),
  (11, 10, 'Mal passada, com sal grosso e sem discussão. Camila tem razão.', 420),
  (11, 12, 'Em Goiás a gente assa até o pequi. Ponto da carne é detalhe.', 410),
  (12, 1, '"Amiga pra sempre" em azul bebê com estrelinhas. Era eu, era 2004, era tudo.', 350),
  (12, 8, 'O meu tinha gif de coração batendo. Ainda bate.', 340),
  (12, 3, 'Fiz um pra Mari com glitter dourado. Ela aprovou em 2 minutos.', 330),
  (12, 13, 'Nasci em 1990, eu era criança. Mas li todos os de vocês e quero um.', 320),
  (13, 4, 'Leva casaco. Sério. La Paz é frio de Curitiba ao quadrado.', 250),
  (13, 11, 'Se passar por Manaus na volta, tacacá por minha conta.', 240),
  (14, 3, 'Reservando o colchão. Levo a câmera e a protetor, você leva o frevo.', 180),
  (14, 7, 'Olinda em fevereiro, Salvador no resto do ano. Fechado.', 170),
  (15, 7, 'Zico, concordo. Mas Adriano merece uma menção honrosa pelo coração.', 60),
  (15, 9, 'Minha filha de 6 anos diz que é o Gabigol. Eu deixo.', 50)
)
INSERT INTO post (id, topic_id, author_id, body, created_at)
SELECT ('ee000000-0000-4000-8000-' || lpad((row_number() over ())::text, 12, '0'))::uuid,
       ('dd000000-0000-4000-8000-0000000000' || lpad(topic::text, 2, '0'))::uuid,
       ('aa000000-0000-4000-8000-0000000000' || lpad(author::text, 2, '0'))::uuid,
       body, now() - make_interval(hours => hours)
FROM p
ON CONFLICT DO NOTHING;

-- The fifteenth person (sprint 5, data): she joined after the fourteen, so
-- the people rail's cap of fourteen and the newest-member states have a row
-- beyond it. Her own rows follow the same shapes; the 015 edges are mirrored
-- by hand as above, and nothing here asks.
INSERT INTO app_user (id, handle, display_name, photo_url, about, relationship, city, country, birthday, passions, music, movies, books, created_at) VALUES
  ('aa000000-0000-4000-8000-000000000015', 'leticia-andrade', 'Letícia Andrade', '/pictures/791318b57c88a811fc57cf44f1f71200af6c41ad17a41c330c49ed6052c50801.jpg', 'Bibliotecária em Belo Horizonte, ciclista de domingo, dona de um gato que se chama Drummond. Entrei porque a Mariana insistiu.', 'rel_single', 'Belo Horizonte, MG', 'Brasil', '1985-09-02', 'bibliotecas públicas, pão de queijo, ciclovias', 'Milton Nascimento, Clube da Esquina, Marisa Monte', 'Bacurau, Central do Brasil', 'Drummond, Adélia Prado, Conceição Evaristo', now() - make_interval(days => 12))
ON CONFLICT DO NOTHING;

INSERT INTO friendship (user_id, friend_id, created_at)
SELECT a, b, now() - make_interval(days => age) FROM (VALUES
  ('aa000000-0000-4000-8000-000000000015'::uuid, 'aa000000-0000-4000-8000-000000000001'::uuid, 11),
  ('aa000000-0000-4000-8000-000000000001'::uuid, 'aa000000-0000-4000-8000-000000000015'::uuid, 11),
  ('aa000000-0000-4000-8000-000000000015'::uuid, 'aa000000-0000-4000-8000-000000000003'::uuid, 9),
  ('aa000000-0000-4000-8000-000000000003'::uuid, 'aa000000-0000-4000-8000-000000000015'::uuid, 9),
  ('aa000000-0000-4000-8000-000000000015'::uuid, 'aa000000-0000-4000-8000-000000000009'::uuid, 6),
  ('aa000000-0000-4000-8000-000000000009'::uuid, 'aa000000-0000-4000-8000-000000000015'::uuid, 6),
  ('aa000000-0000-4000-8000-000000000015'::uuid, 'aa000000-0000-4000-8000-000000000002'::uuid, 3),
  ('aa000000-0000-4000-8000-000000000002'::uuid, 'aa000000-0000-4000-8000-000000000015'::uuid, 3)) AS e (a, b, age)
ON CONFLICT DO NOTHING;

INSERT INTO membership (community_id, user_id, created_at)
SELECT c, 'aa000000-0000-4000-8000-000000000015', now() - make_interval(days => age) FROM (VALUES
  ('cc000000-0000-4000-8000-000000000003'::uuid, 10), ('cc000000-0000-4000-8000-000000000007'::uuid, 8), ('cc000000-0000-4000-8000-000000000005'::uuid, 4)) AS m (c, age)
ON CONFLICT DO NOTHING;

INSERT INTO scrap (id, owner_id, author_id, body, created_at)
SELECT ('de150000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid, o, a, body, now() - make_interval(hours => h) FROM (VALUES
  (1, 'aa000000-0000-4000-8000-000000000001'::uuid, 'aa000000-0000-4000-8000-000000000015'::uuid, 'Mari, entrei! Agora você me deve o caderno que prometeu em 2004.', 260),
  (2, 'aa000000-0000-4000-8000-000000000015'::uuid, 'aa000000-0000-4000-8000-000000000001'::uuid, 'Lê! Bem-vinda. O caderno está a caminho, juro pelo Drummond.', 250),
  (3, 'aa000000-0000-4000-8000-000000000009'::uuid, 'aa000000-0000-4000-8000-000000000015'::uuid, 'Patrícia, a playlist de Clube da Esquina que você montou salvou meu domingo.', 120),
  (4, 'aa000000-0000-4000-8000-000000000015'::uuid, 'aa000000-0000-4000-8000-000000000003'::uuid, 'Lê, manda a foto do Drummond (o gato) pra comunidade do café. Ele merece.', 70)) AS s (n, o, a, body, h)
ON CONFLICT DO NOTHING;

INSERT INTO topic (id, community_id, author_id, title, body, created_at) VALUES
  ('dd150000-0000-4000-8000-000000000001', 'cc000000-0000-4000-8000-000000000007', 'aa000000-0000-4000-8000-000000000015', 'Churrasco de bibliotecária: o que levar quando você não come carne?', 'Sou a vegetariana do rodízio. Levo pão de alho e abacaxi grelhado e fico feliz; alguém tem receita melhor?', now() - make_interval(days => 7))
ON CONFLICT DO NOTHING;

INSERT INTO membership (community_id, user_id, created_at) VALUES
  ('cc000000-0000-4000-8000-000000000007', 'aa000000-0000-4000-8000-000000000014', now() - make_interval(days => 9))
ON CONFLICT DO NOTHING;

INSERT INTO post (id, topic_id, author_id, body, created_at)
SELECT ('ee150000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid, 'dd150000-0000-4000-8000-000000000001', a, body, now() - make_interval(hours => h) FROM (VALUES
  (1, 'aa000000-0000-4000-8000-000000000014'::uuid, 'Queijo coalho no espeto, Letícia. Com melado. Você não vai mais querer carne.', 160),
  (2, 'aa000000-0000-4000-8000-000000000015'::uuid, 'André, você acaba de virar meu churrasqueiro oficial.', 150)) AS p (n, a, body, h)
ON CONFLICT DO NOTHING;

INSERT INTO fan (fan_id, idol_id, created_at)
SELECT f, i, now() - make_interval(days => 5) FROM (VALUES
  ('aa000000-0000-4000-8000-000000000015'::uuid, 'aa000000-0000-4000-8000-000000000001'::uuid),
  ('aa000000-0000-4000-8000-000000000003'::uuid, 'aa000000-0000-4000-8000-000000000015'::uuid),
  ('aa000000-0000-4000-8000-000000000009'::uuid, 'aa000000-0000-4000-8000-000000000015'::uuid)) AS f (f, i)
ON CONFLICT DO NOTHING;

-- The place reads lived-in (sprint 5, data): an old scrap from months back,
-- a topic nobody has answered yet, and a first reply on a thread that had
-- none, from someone outside its opener's circle.
INSERT INTO scrap (id, owner_id, author_id, body, created_at) VALUES
  ('de160000-0000-4000-8000-000000000001', 'aa000000-0000-4000-8000-000000000003', 'aa000000-0000-4000-8000-000000000006', 'Ju, achei a foto do Carnaval de 2019 que a gente tirou na ladeira. Vou escanear e te mando, promessa de bloco.', now() - make_interval(days => 84)),
  ('de160000-0000-4000-8000-000000000002', 'aa000000-0000-4000-8000-000000000008', 'aa000000-0000-4000-8000-000000000012', 'Fê, o livro que você emprestou tá comigo desde março. Eu sei. Eu sei.', now() - make_interval(days => 61))
ON CONFLICT DO NOTHING;
INSERT INTO topic (id, community_id, author_id, title, body, created_at) VALUES
  ('dd160000-0000-4000-8000-000000000001', 'cc000000-0000-4000-8000-000000000004', 'aa000000-0000-4000-8000-000000000002', 'Alguém ainda usa Delphi em 2004?', 'Pergunta séria. Tenho um sistema de estoque em Delphi 7 que ninguém quer encostar e tô pensando em reescrever. Em quê?', now() - make_interval(days => 2))
ON CONFLICT DO NOTHING;



COMMIT;
