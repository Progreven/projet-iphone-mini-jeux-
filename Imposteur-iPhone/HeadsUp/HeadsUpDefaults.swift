import Foundation

enum HeadsUpDefaults {
    static let celebrities: [String] = [
        "Kylian Mbappé", "Zinédine Zidane", "Teddy Riner", "Léon Marchand", "Tony Parker",
        "Yannick Noah", "Antoine Griezmann", "Omar Sy", "Jean Dujardin", "Marion Cotillard",
        "Sophie Marceau", "Dany Boon", "Jamel Debbouze", "Gad Elmaleh", "Florence Foresti",
        "Louis de Funès", "Alain Delon", "Brigitte Bardot", "Audrey Tautou", "Pierre Richard",
        "Jean-Jacques Goldman", "Johnny Hallyday", "Édith Piaf", "Charles Aznavour", "Mylène Farmer",
        "Aya Nakamura", "Vianney", "Soprano", "Gims", "Orelsan",
        "Jul", "Clara Luciani", "Angèle", "Stromae", "David Guetta",
        "DJ Snake", "Patrick Bruel", "Vanessa Paradis", "Michel Sardou", "Renaud",
        "Marie Curie", "Louis Pasteur", "Victor Hugo", "Gustave Eiffel", "Claude Monet",
        "Antoine de Saint-Exupéry", "Molière", "Auguste Rodin", "Thomas Pesquet", "Philippe Etchebest",
        "Taylor Swift", "Beyoncé", "Rihanna", "Lady Gaga", "Billie Eilish",
        "Ariana Grande", "Ed Sheeran", "Adele", "Bruno Mars", "The Weeknd",
        "Justin Bieber", "Dua Lipa", "Shakira", "Jennifer Lopez", "Céline Dion",
        "Eminem", "Snoop Dogg", "Drake", "Kendrick Lamar", "Bad Bunny",
        "Michael Jackson", "Elvis Presley", "Freddie Mercury", "Madonna", "Bob Marley",
        "David Bowie", "Whitney Houston", "Prince", "Tina Turner", "Marilyn Monroe",
        "Leonardo DiCaprio", "Brad Pitt", "Tom Cruise", "Dwayne Johnson", "Will Smith",
        "Morgan Freeman", "Keanu Reeves", "Robert Downey Jr.", "Scarlett Johansson", "Zendaya",
        "Cristiano Ronaldo", "Lionel Messi", "LeBron James", "Michael Jordan", "Usain Bolt",
        "Serena Williams", "Roger Federer", "Rafael Nadal", "Lewis Hamilton", "Albert Einstein"
    ]

    static let moviesSeries: [String] = [
        "Harry Potter", "Hermione Granger", "Ron Weasley", "Voldemort", "Dark Vador",
        "Luke Skywalker", "Princesse Leia", "Han Solo", "Yoda", "Obi-Wan Kenobi",
        "Indiana Jones", "James Bond", "Jack Sparrow", "Rocky Balboa", "Rambo",
        "Neo", "Terminator", "Forrest Gump", "Sherlock Holmes", "Wednesday Addams",
        "Eleven", "Walter White", "Jesse Pinkman", "Saul Goodman", "Jon Snow",
        "Daenerys Targaryen", "Tyrion Lannister", "Rick Grimes", "Daryl Dixon", "Michael Scott",
        "Sheldon Cooper", "Joey Tribbiani", "Rachel Green", "Dexter Morgan", "Docteur House",
        "Thomas Shelby", "Homelander", "Le Mandalorien", "Grogu", "Loki",
        "Iron Man", "Captain America", "Thor", "Hulk", "Spider-Man",
        "Batman", "Joker", "Superman", "Wonder Woman", "Deadpool",
        "Wolverine", "Black Panther", "Doctor Strange", "Thanos", "Gandalf",
        "Frodon", "Aragorn", "Legolas", "Gollum", "Sauron",
        "Katniss Everdeen", "John Wick", "Marty McFly", "Doc Brown", "Barbie",
        "Ken", "E.T.", "Beetlejuice", "Edward aux mains d’argent", "Pennywise",
        "Freddy Krueger", "Jason Voorhees", "Ghostface", "Hannibal Lecter", "Lara Croft",
        "Ethan Hunt", "Maximus", "Achille", "Le Masque", "Ace Ventura",
        "Venom", "Harley Quinn", "Aquaman", "Flash", "Daredevil",
        "Le Punisher", "Mercredi Addams", "Geralt de Riv", "Ciri", "Joel Miller",
        "Ellie Williams", "Merlin", "Robin des Bois", "Zorro", "Dracula",
        "Frankenstein", "Tarzan", "King Kong", "Godzilla", "Jurassic Park T-Rex"
    ]

    static let animationAnime: [String] = [
        "Mickey Mouse", "Minnie Mouse", "Donald Duck", "Dingo", "Simba",
        "Timon", "Pumbaa", "Stitch", "Elsa", "Olaf",
        "Aladdin", "Le Génie", "Mulan", "Vaiana", "Ariel",
        "Buzz l’Éclair", "Woody", "Nemo", "Dory", "Flash McQueen",
        "Shrek", "L’Âne", "Po", "Krokmou", "Gru",
        "Un Minion", "Bob l’éponge", "Patrick Étoile", "Scooby-Doo", "Tom",
        "Jerry", "Bugs Bunny", "Titi", "Grosminet", "Taz",
        "Popeye", "Lucky Luke", "Astérix", "Obélix", "Tintin",
        "Milou", "Gaston Lagaffe", "Titeuf", "Naruto Uzumaki", "Sasuke Uchiwa",
        "Kakashi Hatake", "Sakura Haruno", "Goku", "Vegeta", "Freezer",
        "Luffy", "Zoro", "Nami", "Sanji", "Chopper",
        "Pikachu", "Sacha Ketchum", "Mewtwo", "Saitama", "Genos",
        "Tanjiro Kamado", "Nezuko Kamado", "Zenitsu", "Inosuke", "Gojo Satoru",
        "Yuji Itadori", "Eren Jäger", "Mikasa Ackerman", "Levi Ackerman", "Light Yagami",
        "L", "Edward Elric", "Alphonse Elric", "Totoro", "Anya Forger",
        "Loid Forger", "Sailor Moon", "Doraemon", "Conan Edogawa", "Gon Freecss",
        "Killua Zoldyck", "Hisoka", "Ichigo Kurosaki", "Rukia Kuchiki", "Jotaro Kujo",
        "Dio Brando", "Deku", "Bakugo", "All Might", "Eren Yeager Titan",
        "Rick Sanchez", "Morty Smith", "Homer Simpson", "Bart Simpson", "Marge Simpson",
        "Peter Griffin", "Stewie Griffin", "Peppa Pig", "Dora l’exploratrice", "SamSam"
    ]

    static let videoGames: [String] = [
        "Mario", "Luigi", "Princesse Peach", "Bowser", "Yoshi",
        "Link", "Princesse Zelda", "Ganondorf", "Kirby", "Samus Aran",
        "Donkey Kong", "Sonic", "Tails", "Knuckles", "Shadow",
        "Steve", "Alex", "Creeper", "Jonesy", "Kratos",
        "Atreus", "Master Chief", "Lara Croft", "Nathan Drake", "Joel",
        "Ellie", "Geralt", "Ciri", "Arthur Morgan", "John Marston",
        "CJ", "Trevor Philips", "Michael De Santa", "Franklin Clinton", "Niko Bellic",
        "Ezio Auditore", "Altaïr", "Agent 47", "Leon Kennedy", "Jill Valentine",
        "Claire Redfield", "Nemesis", "Doom Slayer", "Gordon Freeman", "Chell",
        "Pac-Man", "Mega Man", "Crash Bandicoot", "Spyro", "Rayman",
        "Sackboy", "Solid Snake", "Cloud Strife", "Sephiroth", "Tifa Lockhart",
        "Aloy", "Commander Shepard", "Marcus Fenix", "Jin Sakai", "Sekiro",
        "Ryu", "Ken Masters", "Chun-Li", "Scorpion", "Sub-Zero",
        "Liu Kang", "Kazuya Mishima", "Heihachi Mishima", "Jinx", "Ahri",
        "Teemo", "Tracer", "Genji", "Mercy", "Reinhardt",
        "D.Va", "Sans", "Papyrus", "Cuphead", "Mugman",
        "Freddy Fazbear", "Bonnie", "Foxy", "Springtrap", "Among Us Crewmate",
        "Fall Guy", "Octane", "Wraith", "Pathfinder", "Vault Boy",
        "Dovahkiin", "Tom Nook", "Isabelle", "Captain Falcon", "Fox McCloud",
        "Little Mac", "Pit", "Bayonetta", "2B", "Hollow Knight"
    ]

    static let animals: [String] = [
        "Chien", "Chat", "Lion", "Tigre", "Éléphant",
        "Girafe", "Zèbre", "Rhinocéros", "Hippopotame", "Gorille",
        "Chimpanzé", "Orang-outan", "Panda", "Ours polaire", "Ours brun",
        "Loup", "Renard", "Hyène", "Guépard", "Léopard",
        "Jaguar", "Puma", "Lynx", "Cerf", "Sanglier",
        "Cheval", "Âne", "Vache", "Mouton", "Chèvre",
        "Cochon", "Lapin", "Hamster", "Souris", "Écureuil",
        "Hérisson", "Chauve-souris", "Kangourou", "Koala", "Paresseux",
        "Dauphin", "Baleine", "Orque", "Requin", "Raie manta",
        "Phoque", "Morse", "Poulpe", "Calamar", "Méduse",
        "Homard", "Crabe", "Étoile de mer", "Hippocampe", "Poisson-clown",
        "Saumon", "Thon", "Espadon", "Tortue", "Crocodile",
        "Alligator", "Serpent", "Cobra", "Python", "Caméléon",
        "Iguane", "Gecko", "Grenouille", "Crapaud", "Aigle",
        "Faucon", "Hibou", "Chouette", "Perroquet", "Flamant rose",
        "Paon", "Pingouin", "Autruche", "Poule", "Canard",
        "Cygne", "Pigeon", "Mouette", "Abeille", "Guêpe",
        "Papillon", "Coccinelle", "Fourmi", "Moustique", "Mouche",
        "Sauterelle", "Scarabée", "Araignée", "Scorpion", "Mante religieuse",
        "Escargot", "Licorne", "Dragon", "Phénix", "Centaure"
    ]

    static func names(for theme: HeadsUpTheme) -> [String] {
        switch theme {
        case .celebrities: return celebrities
        case .moviesSeries: return moviesSeries
        case .animationAnime: return animationAnime
        case .videoGames: return videoGames
        case .animals: return animals
        case .all: return []
        }
    }
}
