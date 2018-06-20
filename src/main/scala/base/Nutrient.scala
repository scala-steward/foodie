package base

sealed trait Nutrient {
  def name: String
}

/* todo: A macro should create the necessary instances from an external source.
         While nutrients should not change on a regular basis,
         it is still more reasonable to stay flexible in this respect.
 */

object Nutrient {

  sealed abstract class MB(override val name: String) extends Nutrient with Type.MassBased

  sealed abstract class EB(override val name: String) extends Nutrient with Type.EnergyBased

  sealed abstract class UB(override val name: String) extends Nutrient with Type.IUBased

  case object Protein extends MB("PROTEIN")

  case object Fat extends MB("FAT (TOTAL LIPIDS)")

  case object Carbohydrate extends MB("CARBOHYDRATE, TOTAL (BY DIFFERENCE)")

  case object Ash extends MB("ASH, TOTAL")

  case object EnergyKCal extends EB("ENERGY (KILOCALORIES)")

  case object Starch extends MB("STARCH")

  case object Sucrose extends MB("SUCROSE")

  case object Glucose extends MB("GLUCOSE")

  case object Fructose extends MB("FRUCTOSE")

  case object Lactose extends MB("LACTOSE")

  case object Maltose extends MB("MALTOSE")

  case object Alcohol extends MB("ALCOHOL")

  case object OxalicAcid extends MB("OXALIC ACID")

  case object Moisture extends MB("MOISTURE")

  case object Mannitol extends MB("MANNITOL")

  case object Sorbitol extends MB("SORBITOL")

  case object Caffeine extends MB("CAFFEINE")

  case object Theobromine extends MB("THEOBROMINE")

  case object EnergyKJ extends MB("ENERGY (KILOJOULES)")

  case object Sugars extends MB("SUGARS, TOTAL")

  case object Galactose extends MB("GALACTOSE")

  case object Fibre extends MB("FIBRE, TOTAL DIETARY")

  case object Calcium extends MB("CALCIUM")

  case object Iron extends MB("IRON")

  case object Magnesium extends MB("MAGNESIUM")

  case object Phosphorus extends MB("PHOSPHORUS")

  case object Potassium extends MB("POTASSIUM")

  case object Sodium extends MB("SODIUM")

  case object Zinc extends MB("ZINC")

  case object Copper extends MB("COPPER")

  case object Manganese extends MB("MANGANESE")

  case object Selenium extends MB("SELENIUM")

  case object Retinol extends MB("RETINOL")

  case object RetinolActivityEquivalents extends MB("RETINOL ACTIVITY EQUIVALENTS")

  case object BetaCarotene extends MB("BETA CAROTENE")

  case object AlphaCarotene extends MB("ALPHA CAROTENE")

  case object AlphaTocopherol extends MB("ALPHA-TOCOPHEROL")

  case object VitaminDIU extends UB("VITAMIN D (INTERNATIONAL UNITS)")

  case object VitaminD2 extends MB("VITAMIN D2, ERGOCALCIFEROL")

  case object VitaminD extends MB("VITAMIN D (D2 + D3)")

  case object BetaCryptoxanthin extends MB("BETA CRYPTOXANTHIN")

  case object Lycopene extends MB("LYCOPENE")

  case object LuteinAndZeaxanthin extends MB("LUTEIN AND ZEAXANTHIN")

  case object BetaTocopherol extends MB("BETA-TOCOPHEROL")

  case object GammaTocopherol extends MB("GAMMA-TOCOPHEROL")

  case object DeltaTocopherol extends MB("DELTA-TOCOPHEROL")

  case object VitaminC extends MB("VITAMIN C")

  case object Thiamin extends MB("THIAMIN")

  case object Riboflavin extends MB("RIBOFLAVIN")

  case object Niacin extends MB("NIACIN (NICOTINIC ACID) PREFORMED")

  case object NiacinEquivalent extends MB("TOTAL NIACIN EQUIVALENT") //todo: hierfür braucht man einen neuen Marker-Typ

  case object PantothenicAcid extends MB("PANTOTHENIC ACID")

  case object VitaminB6 extends MB("VITAMIN B-6")

  case object Biotin extends MB("BIOTIN")

  case object Folacin extends MB("TOTAL FOLACIN")

  case object VitaminB12 extends MB("VITAMIN B-12")

  case object Choline extends MB("CHOLINE, TOTAL")

  case object VitaminK extends MB("VITAMIN K")

  case object FolicAcid extends MB("FOLIC ACID")

  case object NaturalFolate extends MB("NATURALLY OCCURRING FOLATE")

  case object FolateEquivalents extends MB("DIETARY FOLATE EQUIVALENTS")

  case object Betaine extends MB("BETAINE")

  case object Tryptophan extends MB("TRYPTOPHAN")

  case object Threonine extends MB("THREONINE")

  case object Isoleucine extends MB("ISOLEUCINE")

  case object Leucine extends MB("LEUCINE")

  case object Lysine extends MB("LYSINE")

  case object Methionine extends MB("METHIONINE")

  case object Cystine extends MB("CYSTINE")

  case object Phenylalanine extends MB("PHENYLALANINE")

  case object Tyrosine extends MB("TYROSINE")

  case object Valine extends MB("VALINE")

  case object Arginine extends MB("ARGININE")

  case object Histidine extends MB("HISTIDINE")

  case object Alanine extends MB("ALANINE")

  case object AsparticAcid extends MB("ASPARTIC ACID")

  case object GlutamicAcid extends MB("GLUTAMIC ACID")

  case object Glycine extends MB("GLYCINE")

  case object Proline extends MB("PROLINE")

  case object Serine extends MB("SERINE")

  case object Hydroxyproline extends MB("HYDROXYPROLINE")

  case object Aspartame extends MB("ASPARTAME")

  case object AlphaTocopherolAdded extends MB("ALPHA-TOCOPHEROL, ADDED")

  case object VitaminB12Added extends MB("VITAMIN B12, ADDED")

  case object Cholesterol extends MB("CHOLESTEROL")

  case object FattyAcidsTrans extends MB("FATTY ACIDS, TRANS, TOTAL")

  case object FattyAcidsSaturated extends MB("FATTY ACIDS, SATURATED, TOTAL")

  case object FattyAcidsSaturatedButanoic extends MB("FATTY ACIDS, SATURATED, 4:0, BUTANOIC")

  case object FattyAcidsSaturatedHexanoic extends MB("FATTY ACIDS, SATURATED, 6:0, HEXANOIC")

  case object FattyAcidsSaturatedOctanoic extends MB("FATTY ACIDS, SATURATED, 8:0, OCTANOIC")

  case object FattyAcidsSaturatedDecanoic extends MB("FATTY ACIDS, SATURATED, 10:0, DECANOIC")

  case object FattyAcidsSaturatedDodecanoic extends MB("FATTY ACIDS, SATURATED, 12:0, DODECANOIC")

  case object FattyAcidsSaturatedTetradecanoic extends MB("FATTY ACIDS, SATURATED, 14:0, TETRADECANOIC")

  case object FattyAcidsSaturatedHexadecanoic extends MB("FATTY ACIDS, SATURATED, 16:0, HEXADECANOIC")

  case object FattyAcidsSaturatedOctadecanoic extends MB("FATTY ACIDS, SATURATED, 18:0, OCTADECANOIC")

  case object FattyAcidsSaturatedEicosanoic extends MB("FATTY ACIDS, SATURATED, 20:0, EICOSANOIC")

  case object FattyAcidsMonounsaturatedOctadecenoicUndifferentiated extends MB("FATTY ACIDS, MONOUNSATURATED, 18:1undifferentiated, OCTADECENOIC")

  case object FattyAcidsPolyunsaturatedOctadecadienoicUndifferentiated extends MB("FATTY ACIDS, POLYUNSATURATED, 18:2undifferentiated, LINOLEIC, OCTADECADIENOIC")

  case object FattyAcidsPolyunsaturatedOctadecatrienoicUndifferentiated extends MB("FATTY ACIDS, POLYUNSATURATED, 18:3undifferentiated, LINOLENIC, OCTADECATRIENOIC")

  case object FattyAcidsPolyunsaturatedEicosatetraenoic extends MB("FATTY ACIDS, POLYUNSATURATED, 20:4, EICOSATETRAENOIC")

  case object FattyAcidsPolyunsaturatedDocosahexaenoic extends MB("FATTY ACIDS, POLYUNSATURATED, 22:6 n-3, DOCOSAHEXAENOIC (DHA)")

  case object FattyAcidsSaturatedDocosanoic extends MB("FATTY ACIDS, SATURATED, 22:0, DOCOSANOIC")

  case object FattyAcidsMonounsaturatedTetradecenoic extends MB("FATTY ACIDS, MONOUNSATURATED, 14:1, TETRADECENOIC")

  case object FattyAcidsMonounsaturatedHexadecenoic extends MB("FATTY ACIDS, MONOUNSATURATED, 16:1undifferentiated, HEXADECENOIC")

  case object FattyAcidsPolyunsaturatedOctadecatetraenoic extends MB("FATTY ACIDS, POLYUNSATURATED, 18:4, OCTADECATETRAENOIC")

  case object FattyAcidsMonounsaturatedEicosenoic extends MB("FATTY ACIDS, MONOUNSATURATED, 20:1, EICOSENOIC")

  case object FattyAcidsPolyunsaturatedEicosapentaenoic extends MB("FATTY ACIDS, POLYUNSATURATED, 20:5 n-3, EICOSAPENTAENOIC (EPA)")

  case object FattyAcidsMonounsaturatedDocosenoicUndifferentiated extends MB("FATTY ACIDS, MONOUNSATURATED, 22:1undifferentiated, DOCOSENOIC")

  case object FattyAcidsPolyunsaturatedDocosapentanoic extends MB("FATTY ACIDS, POLYUNSATURATED, 22:5 n-3, DOCOSAPENTAENOIC (DPA)")

  case object PlantSterol extends MB("TOTAL PLANT STEROL")

  case object StigmaSterol extends MB("STIGMASTEROL")

  case object CampeSterol extends MB("CAMPESTEROL")

  case object BetaSitoSterol extends MB("BETA-SITOSTEROL")

  case object FattyAcidsMonounsaturatedTotal extends MB("FATTY ACIDS, MONOUNSATURATED, TOTAL")

  case object FattyAcidsPolyunsaturatedTotal extends MB("FATTY ACIDS, POLYUNSATURATED, TOTAL")

  case object FattyAcidsSaturatedPentadecanoic extends MB("FATTY ACIDS, SATURATED, 15:0, PENTADECANOIC")

  case object FattyAcidsSaturatedHeptadecanoic extends MB("FATTY ACIDS, SATURATED, 17:0, HEPTADECANOIC")

  case object FattyAcidsSaturatedTetracosanoic extends MB("FATTY ACIDS, SATURATED, 24:0, TETRACOSANOIC")

  case object FattyAcidsMonounsaturatedHexadecenoicT extends MB("FATTY ACIDS, MONOUNSATURATED, 16:1t, HEXADECENOIC")

  case object FattyAcidsMonounsaturatedOctadecenoicT extends MB("FATTY ACIDS, MONOUNSATURATED, 18:1t, OCTADECENOIC")

  case object FattyAcidsMonounsaturatedDocosenoicT extends MB("FATTY ACIDS, MONOUNSATURATED, 22:1t, DOCOSENOIC")

  case object FattyAcidsPolyunsaturatedLinoleicOctadecadienoicI extends MB("FATTY ACIDS, POLYUNSATURATED, 18:2i, LINOLEIC, OCTADECADIENOIC")

  case object FattyAcidsPolyunsaturatedOctadecadienoic extends MB("FATTY ACIDS, POLYUNSATURATED, 18:2t,t , OCTADECADIENENOIC")

  case object FattyAcidsPolyunsaturatedLinoleicOctadecadienoicConjugated extends MB("FATTY ACIDS, POLYUNSATURATED, CONJUGATED, 18:2 cla, LINOLEIC, OCTADECADIENOIC")

  case object FattyAcidsMonounsaturatedTetracosenoic extends MB("FATTY ACIDS, MONOUNSATURATED, 24:1c, TETRACOSENOIC")

  case object FattyAcidsPolyunsaturatedEicosadienoic extends MB("FATTY ACIDS, POLYUNSATURATED, 20:2 c,c  EICOSADIENOIC")

  case object FattyAcidsMonounsaturatedHexadecenoicC extends MB("FATTY ACIDS, MONOUNSATURATED, 16:1c, HEXADECENOIC")

  case object FattyAcidsMonounsaturatedOctadecenoicC extends MB("FATTY ACIDS, MONOUNSATURATED, 18:1c, OCTADECENOIC")

  case object FattyAcidsPolyunsaturatedLinoleicOctadecadienoicC extends MB("FATTY ACIDS, POLYUNSATURATED, 18:2 c,c n-6,  LINOLEIC, OCTADECADIENOIC")

  case object FattyAcidsMonounsaturatedDocosenoicC extends MB("FATTY ACIDS, MONOUNSATURATED, 22:1c, DOCOSENOIC")

  case object FattyAcidsPolyunsaturatedOctadecatrienoicN6 extends MB("FATTY ACIDS, POLYUNSATURATED, 18:3 c,c,c n-6, g-LINOLENIC, OCTADECATRIENOIC")

  case object FattyAcidsMonounsaturatedHeptadecenoic extends MB("FATTY ACIDS, MONOUNSATURATED, 17:1, HEPTADECENOIC")

  case object FattyAcidsPolyunsaturatedEicosatrienoic extends MB("FATTY ACIDS, POLYUNSATURATED, 20:3, EICOSATRIENOIC")

  case object FattyAcidsTransnonoenoicTransMonoenoic extends MB("FATTY ACIDS, TOTAL TRANS-MONOENOIC")

  case object FattyAcidsTranspolyenoicTransPolyenoic extends MB("FATTY ACIDS, TOTAL TRANS-POLYENOIC")

  case object FattyAcidsSaturatedTridecanoic extends MB("FATTY ACIDS, SATURATED, 13:0 TRIDECANOIC")

  case object FattyAcidsMonounsaturatedPentadecenoic extends MB("FATTY ACIDS, MONOUNSATURATED, 15:1, PENTADECENOIC")

  case object Monosaccharides extends MB("TOTAL MONOSACCARIDES")

  case object Disaccharides extends MB("TOTAL DISACCHARIDES")

  case object FattyAcidsPolyunsaturatedOctadecatrienoicN3 extends MB("FATTY ACIDS, POLYUNSATURATED, 18:3 c,c,c n-3  LINOLENIC, OCTADECATRIENOIC")

  case object FattyAcidsPolyunsaturatedEicosatrienoicN3 extends MB("FATTY ACIDS, POLYUNSATURATED, 20:3 n-3 EICOSATRIENOIC")

  case object FattyAcidsPolyunsaturatedEicosatrienoicN6 extends MB("FATTY ACIDS, POLYUNSATURATED, 20:3 n-6, EICOSATRIENOIC")

  case object FattyAcidsPolyunsaturatedArachidonic extends MB("FATTY ACIDS, POLYUNSATURATED, 20:4 n-6, ARACHIDONIC")

  case object FattyAcidsPolyunsaturatedOctadecatrienoic extends MB("FATTY ACIDS, POLYUNSATURATED, 18:3i, LINOLENIC, OCTADECATRIENOIC")

  case object FattyAcidsPolyunsaturated215 extends MB("FATTY ACIDS, POLYUNSATURATED, 21:5")

  case object FattyAcidsPolyunsaturatedDocosatetraenoic extends MB("FATTY ACIDS, POLYUNSATURATED, 22:4 n-6, DOCOSATETRAENOIC")

  case object FattyAcidsMonounsaturatedTetracosenoicUndifferentiated extends MB("FATTY ACIDS, MONOUNSATURATED,  24:1undifferentiated, TETRACOSENOIC")

  case object FattyAcidsMonounsaturatedLauroleic extends MB("FATTY ACIDS, MONOUNSATURATED, 12:1, LAUROLEIC")

  case object FattyAcidsPolyunsaturated223 extends MB("FATTY ACIDS, POLYUNSATURATED, 22:3,")

  case object FattyAcidsPolyunsaturatedDocosadienoic extends MB("FATTY ACIDS, POLYUNSATURATED, 22:2, DOCOSADIENOIC")

  case object FattyAcidsPolyunsaturatedOmega3 extends MB("FATTY ACIDS, POLYUNSATURATED, TOTAL OMEGA  N-3")

  case object FattyAcidsPolyunsaturatedOmega6 extends MB("FATTY ACIDS, POLYUNSATURATED, TOTAL OMEGA   N-6")

  val all: Traversable[(Nutrient, String)] = Traversable(
    Protein -> Protein.name,
    Fat -> Fat.name,
    Carbohydrate -> Carbohydrate.name,
    Ash -> Ash.name,
    EnergyKCal -> EnergyKCal.name,
    Starch -> Starch.name,
    Sucrose -> Sucrose.name,
    Glucose -> Glucose.name,
    Fructose -> Fructose.name,
    Lactose -> Lactose.name,
    Maltose -> Maltose.name,
    Alcohol -> Alcohol.name,
    OxalicAcid -> OxalicAcid.name,
    Moisture -> Moisture.name,
    Mannitol -> Mannitol.name,
    Sorbitol -> Sorbitol.name,
    Caffeine -> Caffeine.name,
    Theobromine -> Theobromine.name,
    EnergyKJ -> EnergyKJ.name,
    Sugars -> Sugars.name,
    Galactose -> Galactose.name,
    Fibre -> Fibre.name,
    Calcium -> Calcium.name,
    Iron -> Iron.name,
    Magnesium -> Magnesium.name,
    Phosphorus -> Phosphorus.name,
    Potassium -> Potassium.name,
    Sodium -> Sodium.name,
    Zinc -> Zinc.name,
    Copper -> Copper.name,
    Manganese -> Manganese.name,
    Selenium -> Selenium.name,
    Retinol -> Retinol.name,
    RetinolActivityEquivalents -> RetinolActivityEquivalents.name,
    BetaCarotene -> BetaCarotene.name,
    AlphaCarotene -> AlphaCarotene.name,
    AlphaTocopherol -> AlphaTocopherol.name,
    VitaminDIU -> VitaminDIU.name,
    VitaminD2 -> VitaminD2.name,
    VitaminD -> VitaminD.name,
    BetaCryptoxanthin -> BetaCryptoxanthin.name,
    Lycopene -> Lycopene.name,
    LuteinAndZeaxanthin -> LuteinAndZeaxanthin.name,
    BetaTocopherol -> BetaTocopherol.name,
    GammaTocopherol -> GammaTocopherol.name,
    DeltaTocopherol -> DeltaTocopherol.name,
    VitaminC -> VitaminC.name,
    Thiamin -> Thiamin.name,
    Riboflavin -> Riboflavin.name,
    Niacin -> Niacin.name,
    NiacinEquivalent -> NiacinEquivalent.name,
    PantothenicAcid -> PantothenicAcid.name,
    VitaminB6 -> VitaminB6.name,
    Biotin -> Biotin.name,
    Folacin -> Folacin.name,
    VitaminB12 -> VitaminB12.name,
    Choline -> Choline.name,
    VitaminK -> VitaminK.name,
    FolicAcid -> FolicAcid.name,
    NaturalFolate -> NaturalFolate.name,
    FolateEquivalents -> FolateEquivalents.name,
    Betaine -> Betaine.name,
    Tryptophan -> Tryptophan.name,
    Threonine -> Threonine.name,
    Isoleucine -> Isoleucine.name,
    Leucine -> Leucine.name,
    Lysine -> Lysine.name,
    Methionine -> Methionine.name,
    Cystine -> Cystine.name,
    Phenylalanine -> Phenylalanine.name,
    Tyrosine -> Tyrosine.name,
    Valine -> Valine.name,
    Arginine -> Arginine.name,
    Histidine -> Histidine.name,
    Alanine -> Alanine.name,
    AsparticAcid -> AsparticAcid.name,
    GlutamicAcid -> GlutamicAcid.name,
    Glycine -> Glycine.name,
    Proline -> Proline.name,
    Serine -> Serine.name,
    Hydroxyproline -> Hydroxyproline.name,
    Aspartame -> Aspartame.name,
    AlphaTocopherolAdded -> AlphaTocopherolAdded.name,
    VitaminB12Added -> VitaminB12Added.name,
    Cholesterol -> Cholesterol.name,
    FattyAcidsTrans -> FattyAcidsTrans.name,
    FattyAcidsSaturated -> FattyAcidsSaturated.name,
    FattyAcidsSaturatedButanoic -> FattyAcidsSaturatedButanoic.name,
    FattyAcidsSaturatedHexanoic -> FattyAcidsSaturatedHexanoic.name,
    FattyAcidsSaturatedOctanoic -> FattyAcidsSaturatedOctanoic.name,
    FattyAcidsSaturatedDecanoic -> FattyAcidsSaturatedDecanoic.name,
    FattyAcidsSaturatedDodecanoic -> FattyAcidsSaturatedDodecanoic.name,
    FattyAcidsSaturatedTetradecanoic -> FattyAcidsSaturatedTetradecanoic.name,
    FattyAcidsSaturatedHexadecanoic -> FattyAcidsSaturatedHexadecanoic.name,
    FattyAcidsSaturatedOctadecanoic -> FattyAcidsSaturatedOctadecanoic.name,
    FattyAcidsSaturatedEicosanoic -> FattyAcidsSaturatedEicosanoic.name,
    FattyAcidsMonounsaturatedOctadecenoicUndifferentiated -> FattyAcidsMonounsaturatedOctadecenoicUndifferentiated.name,
    FattyAcidsPolyunsaturatedOctadecadienoicUndifferentiated -> FattyAcidsPolyunsaturatedOctadecadienoicUndifferentiated.name,
    FattyAcidsPolyunsaturatedOctadecatrienoicUndifferentiated -> FattyAcidsPolyunsaturatedOctadecatrienoicUndifferentiated.name,
    FattyAcidsPolyunsaturatedEicosatetraenoic -> FattyAcidsPolyunsaturatedEicosatetraenoic.name,
    FattyAcidsPolyunsaturatedDocosahexaenoic -> FattyAcidsPolyunsaturatedDocosahexaenoic.name,
    FattyAcidsSaturatedDocosanoic -> FattyAcidsSaturatedDocosanoic.name,
    FattyAcidsMonounsaturatedTetradecenoic -> FattyAcidsMonounsaturatedTetradecenoic.name,
    FattyAcidsMonounsaturatedHexadecenoic -> FattyAcidsMonounsaturatedHexadecenoic.name,
    FattyAcidsPolyunsaturatedOctadecatetraenoic -> FattyAcidsPolyunsaturatedOctadecatetraenoic.name,
    FattyAcidsMonounsaturatedEicosenoic -> FattyAcidsMonounsaturatedEicosenoic.name,
    FattyAcidsPolyunsaturatedEicosapentaenoic -> FattyAcidsPolyunsaturatedEicosapentaenoic.name,
    FattyAcidsMonounsaturatedDocosenoicUndifferentiated -> FattyAcidsMonounsaturatedDocosenoicUndifferentiated.name,
    FattyAcidsPolyunsaturatedDocosapentanoic -> FattyAcidsPolyunsaturatedDocosapentanoic.name,
    PlantSterol -> PlantSterol.name,
    StigmaSterol -> StigmaSterol.name,
    CampeSterol -> CampeSterol.name,
    BetaSitoSterol -> BetaSitoSterol.name,
    FattyAcidsMonounsaturatedTotal -> FattyAcidsMonounsaturatedTotal.name,
    FattyAcidsPolyunsaturatedTotal -> FattyAcidsPolyunsaturatedTotal.name,
    FattyAcidsSaturatedPentadecanoic -> FattyAcidsSaturatedPentadecanoic.name,
    FattyAcidsSaturatedHeptadecanoic -> FattyAcidsSaturatedHeptadecanoic.name,
    FattyAcidsSaturatedTetracosanoic -> FattyAcidsSaturatedTetracosanoic.name,
    FattyAcidsMonounsaturatedHexadecenoicT -> FattyAcidsMonounsaturatedHexadecenoicT.name,
    FattyAcidsMonounsaturatedOctadecenoicT -> FattyAcidsMonounsaturatedOctadecenoicT.name,
    FattyAcidsMonounsaturatedDocosenoicT -> FattyAcidsMonounsaturatedDocosenoicT.name,
    FattyAcidsPolyunsaturatedLinoleicOctadecadienoicI -> FattyAcidsPolyunsaturatedLinoleicOctadecadienoicI.name,
    FattyAcidsPolyunsaturatedOctadecadienoic -> FattyAcidsPolyunsaturatedOctadecadienoic.name,
    FattyAcidsPolyunsaturatedLinoleicOctadecadienoicConjugated -> FattyAcidsPolyunsaturatedLinoleicOctadecadienoicConjugated.name,
    FattyAcidsMonounsaturatedTetracosenoic -> FattyAcidsMonounsaturatedTetracosenoic.name,
    FattyAcidsPolyunsaturatedEicosadienoic -> FattyAcidsPolyunsaturatedEicosadienoic.name,
    FattyAcidsMonounsaturatedHexadecenoicC -> FattyAcidsMonounsaturatedHexadecenoicC.name,
    FattyAcidsMonounsaturatedOctadecenoicC -> FattyAcidsMonounsaturatedOctadecenoicC.name,
    FattyAcidsPolyunsaturatedLinoleicOctadecadienoicC -> FattyAcidsPolyunsaturatedLinoleicOctadecadienoicC.name,
    FattyAcidsMonounsaturatedDocosenoicC -> FattyAcidsMonounsaturatedDocosenoicC.name,
    FattyAcidsPolyunsaturatedOctadecatrienoicN6 -> FattyAcidsPolyunsaturatedOctadecatrienoicN6.name,
    FattyAcidsMonounsaturatedHeptadecenoic -> FattyAcidsMonounsaturatedHeptadecenoic.name,
    FattyAcidsPolyunsaturatedEicosatrienoic -> FattyAcidsPolyunsaturatedEicosatrienoic.name,
    FattyAcidsTransnonoenoicTransMonoenoic -> FattyAcidsTransnonoenoicTransMonoenoic.name,
    FattyAcidsTranspolyenoicTransPolyenoic -> FattyAcidsTranspolyenoicTransPolyenoic.name,
    FattyAcidsSaturatedTridecanoic -> FattyAcidsSaturatedTridecanoic.name,
    FattyAcidsMonounsaturatedPentadecenoic -> FattyAcidsMonounsaturatedPentadecenoic.name,
    Monosaccharides -> Monosaccharides.name,
    Disaccharides -> Disaccharides.name,
    FattyAcidsPolyunsaturatedOctadecatrienoicN3 -> FattyAcidsPolyunsaturatedOctadecatrienoicN3.name,
    FattyAcidsPolyunsaturatedEicosatrienoicN3 -> FattyAcidsPolyunsaturatedEicosatrienoicN3.name,
    FattyAcidsPolyunsaturatedEicosatrienoicN6 -> FattyAcidsPolyunsaturatedEicosatrienoicN6.name,
    FattyAcidsPolyunsaturatedArachidonic -> FattyAcidsPolyunsaturatedArachidonic.name,
    FattyAcidsPolyunsaturatedOctadecatrienoic -> FattyAcidsPolyunsaturatedOctadecatrienoic.name,
    FattyAcidsPolyunsaturated215 -> FattyAcidsPolyunsaturated215.name,
    FattyAcidsPolyunsaturatedDocosatetraenoic -> FattyAcidsPolyunsaturatedDocosatetraenoic.name,
    FattyAcidsMonounsaturatedTetracosenoicUndifferentiated -> FattyAcidsMonounsaturatedTetracosenoicUndifferentiated.name,
    FattyAcidsMonounsaturatedLauroleic -> FattyAcidsMonounsaturatedLauroleic.name,
    FattyAcidsPolyunsaturated223 -> FattyAcidsPolyunsaturated223.name,
    FattyAcidsPolyunsaturatedDocosadienoic -> FattyAcidsPolyunsaturatedDocosadienoic.name,
    FattyAcidsPolyunsaturatedOmega3 -> FattyAcidsPolyunsaturatedOmega3.name,
    FattyAcidsPolyunsaturatedOmega6 -> FattyAcidsPolyunsaturatedOmega6.name
  )

  def fromString(name: String): Option[Nutrient] = {
    all.find(_._2 == name).map(_._1)
  }
}